#!/bin/bash

# Script to configure Raspberry Pi as a USB Mass Storage Gadget
# This allows the SamplePi media directories to be accessed as a USB drive
# 
# ON-DEMAND MODE: This setup enables toggling gadget mode via long-press
# of the top button (GPIO 5) on the SamplePi interface.

set -e  # Exit on any error

echo "Setting up Raspberry Pi as USB Mass Storage Gadget for SamplePi..."
echo ""
echo "This setup enables ON-DEMAND gadget mode:"
echo "  - Long-press TOP button (GPIO 5) to toggle USB gadget mode"
echo "  - Pi will reboot and appear as 'SamplePi Media Storage'"
echo "  - Long-press TOP button again to exit gadget mode"
echo ""

# Check if running on Raspberry Pi
if ! [ -f /proc/device-tree/model ]; then
    echo "Error: This script is intended to run on a Raspberry Pi"
    exit 1
fi

# Get current username
CURRENT_USER=$(whoami)

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "This script should not be run as root. Please run as a regular user (e.g., pi or samplepi)."
    exit 1
fi

# Define media directory paths (using current user's home directory)
HOME_DIR="/home/$CURRENT_USER"
MEDIA_ROOT="$HOME_DIR/media"
SAMPLES_DIR="$MEDIA_ROOT/samples"
TEST_WAVS_DIR="$MEDIA_ROOT/test_wavs"

# Also check if the application is using the default test_media directory
# and adjust accordingly for consistency
APP_MEDIA_ROOT="$HOME_DIR/SamplePi/test_media"
APP_SAMPLES_DIR="$APP_MEDIA_ROOT/samples"
APP_TEST_WAVS_DIR="$APP_MEDIA_ROOT/test_wavs"

# Create media directories if they don't exist
mkdir -p "$SAMPLES_DIR"
mkdir -p "$TEST_WAVS_DIR"

# Calculate required image size (estimate based on current content + buffer)
CURRENT_SIZE=$(du -sb "$MEDIA_ROOT" 2>/dev/null | cut -f1)
IMAGE_SIZE=$((CURRENT_SIZE + 100*1024*1024))  # Add 100MB buffer
IMAGE_SIZE_MB=$((IMAGE_SIZE / 1024 / 1024))
IMAGE_SIZE_MB=$((IMAGE_SIZE_MB + 100))  # Round up

echo "Creating mass storage image of size ${IMAGE_SIZE_MB}MB..."

# Create the mass storage image file
sudo dd if=/dev/zero of=$HOME_DIR/samplepi_media_storage.img bs=1M count=$IMAGE_SIZE_MB
sudo mkfs.vfat $HOME_DIR/samplepi_media_storage.img

# Mount the image temporarily to set up directory structure
sudo mkdir -p /mnt/gadget_temp
sudo mount -o loop $HOME_DIR/samplepi_media_storage.img /mnt/gadget_temp

# Copy existing media files to the image
sudo cp -r "$SAMPLES_DIR" /mnt/gadget_temp/ 2>/dev/null || echo "No samples to copy"
sudo cp -r "$TEST_WAVS_DIR" /mnt/gadget_temp/ 2>/dev/null || echo "No test WAVs to copy"

# Create default directories if they don't exist in the image
sudo mkdir -p /mnt/gadget_temp/samples
sudo mkdir -p /mnt/gadget_temp/test_wavs

sudo umount /mnt/gadget_temp
sudo rmdir /mnt/gadget_temp

echo "Mass storage image created successfully."

# Enable dwc2 overlay in config.txt (one-time hardware config, requires one reboot)
# After this reboot, toggle_gadget_button.sh activates/deactivates the gadget at runtime
# with no further reboots needed.
if [ -f "/boot/firmware/config.txt" ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
else
    CONFIG_FILE="/boot/config.txt"
fi
if ! grep -q "dtoverlay=dwc2" "$CONFIG_FILE"; then
    echo "dtoverlay=dwc2" | sudo tee -a "$CONFIG_FILE"
    echo "Added dtoverlay=dwc2 to $CONFIG_FILE (reboot required once)"
else
    echo "dtoverlay=dwc2 already present in $CONFIG_FILE"
fi

# Create the USB gadget configuration script
GADGET_SCRIPT="/usr/local/bin/configure_usb_gadget.sh"
sudo tee "$GADGET_SCRIPT" > /dev/null << 'EOF'
#!/bin/bash

# USB Gadget Configuration Script for SamplePi
# This script sets up the Raspberry Pi as a USB Mass Storage device

GADGET_PATH="/sys/kernel/config/usb_gadget/samplepi"
STORAGE_IMG="SAMPLEPI_HOME_DIR/samplepi_media_storage.img"

# Check if gadget is already configured
if [ -d "$GADGET_PATH" ]; then
    echo "USB gadget already configured"
    exit 0
fi

# Create gadget directory
sudo mkdir -p "$GADGET_PATH"
cd "$GADGET_PATH"

# Set vendor and product IDs (Linux Foundation IDs)
echo 0x1d6b | sudo tee idVendor   # Linux Foundation
echo 0x0104 | sudo tee idProduct  # Multifunction Composite Gadget

# Set device version
echo 0x0100 | sudo tee bcdDevice  # v1.0.0
echo 0x0200 | sudo tee bcdUSB    # USB 2.0

# Create strings
sudo mkdir -p strings/0x409
echo "SamplePi" | sudo tee strings/0x409/manufacturer
echo "SamplePi USB Mass Storage" | sudo tee strings/0x409/product
echo "SP123456789" | sudo tee strings/0x409/serialnumber

# Create configuration
sudo mkdir -p configs/c.1/strings/0x409
echo "SamplePi Config" | sudo tee configs/c.1/strings/0x409/configuration
echo 250 | sudo tee configs/c.1/MaxPower

# Create mass storage function
sudo mkdir -p functions/mass_storage.usb0

# Point to our storage image
echo "$STORAGE_IMG" | sudo tee functions/mass_storage.usb0/lun.0/file
echo 1 | sudo tee functions/mass_storage.usb0/lun.0/removable
echo "SamplePi Media Storage" | sudo tee functions/mass_storage.usb0/lun.0/inquiry_string

# Link function to configuration
sudo ln -s functions/mass_storage.usb0 configs/c.1/

# Enable the gadget
ls /sys/class/udc | sudo tee UDC

echo "USB Mass Storage Gadget enabled!"
EOF

# Install the toggle script for button-triggered gadget mode
TOGGLE_SCRIPT="/usr/local/bin/samplepi_toggle_gadget.sh"
sudo cp $HOME_DIR/SamplePi/usb_gadget/toggle_gadget_button.sh "$TOGGLE_SCRIPT"
sudo chmod +x "$TOGGLE_SCRIPT"
echo "USB gadget toggle script installed at $TOGGLE_SCRIPT"

# Create sudoers entry for toggle script (allows user to run it without password)
SUDOERS_FILE="/etc/sudoers.d/samplepi_toggle"
if [ ! -f "$SUDOERS_FILE" ]; then
    echo "$CURRENT_USER ALL=(ALL) NOPASSWD: $TOGGLE_SCRIPT" | sudo tee "$SUDOERS_FILE"
    sudo chmod 440 "$SUDOERS_FILE"
    echo "Created sudoers entry for toggle script"
fi

# Create a symlink in SamplePi directory for easy access
ln -sf $HOME_DIR/SamplePi/usb_gadget/toggle_gadget_button.sh $HOME_DIR/SamplePi/toggle_gadget.sh 2>/dev/null || true

echo ""
echo "========================================"
echo "Setup complete!"
echo "========================================"
echo ""
echo "IMPORTANT: Reboot once now to activate dtoverlay=dwc2:"
echo "   sudo reboot"
echo ""
echo "After that single reboot, USB Gadget Mode toggles instantly (no more reboots):"
echo ""
echo "  - Long-press TOP button (GPIO 5) to enable USB Gadget Mode"
echo "    Pi appears as 'SamplePi Media Storage' on your computer"
echo "  - Long-press TOP button again to disable and sync files back"
echo ""
echo "Manual toggle command:"
echo "   sudo $TOGGLE_SCRIPT"
echo ""