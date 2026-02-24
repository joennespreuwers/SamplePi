#!/bin/bash

# USB Gadget Mode Toggle Script for SamplePi
# Safely enables or disables USB gadget mode with configuration backup
# Designed to be triggered by long-press of top button (GPIO 5)

set -e  # Exit on any error

# Get current user's home directory
CURRENT_USER=$(whoami)
HOME_DIR="/home/$CURRENT_USER"

CONFIG_FILE="/boot/config.txt"
CONFIG_BACKUP="/boot/config.txt.backup"
GADGET_SERVICE="usb-gadget.service"
GADGET_SCRIPT="/usr/local/bin/configure_usb_gadget.sh"
STORAGE_IMG="$HOME_DIR/samplepi_media_storage.img"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Raspberry Pi
check_raspberry_pi() {
    if ! [ -f /proc/device-tree/model ]; then
        log_error "This script is intended to run on a Raspberry Pi"
        exit 1
    fi
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Check current gadget mode status
is_gadget_mode() {
    if [ -d "/sys/kernel/config/usb_gadget/samplepi" ] && \
       [ -f "/sys/kernel/config/usb_gadget/samplepi/UDC" ] && \
       [ -s "/sys/kernel/config/usb_gadget/samplepi/UDC" ]; then
        return 0  # true - gadget is active
    fi
    return 1  # false - gadget is not active
}

# Check if gadget service is enabled
is_gadget_service_enabled() {
    if systemctl is-enabled --quiet "$GADGET_SERVICE" 2>/dev/null; then
        return 0  # true
    fi
    return 1  # false
}

# Backup config.txt if not already backed up
backup_config() {
    if [ ! -f "$CONFIG_BACKUP" ]; then
        cp "$CONFIG_FILE" "$CONFIG_BACKUP"
        log_info "Created backup of config.txt"
    fi
}

# Enable USB gadget mode
enable_gadget_mode() {
    log_info "Enabling USB Gadget Mode..."
    
    # Backup config first
    backup_config()
    
    # Add dwc2 overlay if not present
    if ! grep -q "dtoverlay=dwc2" "$CONFIG_FILE"; then
        echo "dtoverlay=dwc2" >> "$CONFIG_FILE"
        log_info "Added dwc2 overlay to config.txt"
    else
        log_info "dwc2 overlay already present in config.txt"
    fi
    
    # Add modules-load to cmdline.txt if not present
    CMDLINE_FILE="/boot/cmdline.txt"
    if ! grep -q "modules-load=dwc2" "$CMDLINE_FILE"; then
        cp "$CMDLINE_FILE" "${CMDLINE_FILE}.backup"
        sed -i "s/$/ modules-load=dwc2,g_mass_storage/" "$CMDLINE_FILE"
        log_info "Added modules-load to cmdline.txt"
    fi
    
    # Create storage image if it doesn't exist
    if [ ! -f "$STORAGE_IMG" ]; then
        log_info "Creating mass storage image..."

        MEDIA_ROOT="$HOME_DIR/media"
        mkdir -p "$MEDIA_ROOT/samples" "$MEDIA_ROOT/test_wavs"

        CURRENT_SIZE=$(du -sb "$MEDIA_ROOT" 2>/dev/null | cut -f1 || echo "0")
        IMAGE_SIZE=$((CURRENT_SIZE + 100*1024*1024))
        IMAGE_SIZE_MB=$((IMAGE_SIZE / 1024 / 1024 + 100))

        dd if=/dev/zero of="$STORAGE_IMG" bs=1M count=$IMAGE_SIZE_MB
        mkfs.vfat "$STORAGE_IMG"

        # Copy existing media to image
        TEMP_MOUNT=$(mktemp -d)
        mount -o loop "$STORAGE_IMG" "$TEMP_MOUNT"
        cp -r "$MEDIA_ROOT/samples" "$TEMP_MOUNT/" 2>/dev/null || true
        cp -r "$MEDIA_ROOT/test_wavs" "$TEMP_MOUNT/" 2>/dev/null || true
        umount "$TEMP_MOUNT"
        rmdir "$TEMP_MOUNT"

        log_info "Mass storage image created (${IMAGE_SIZE_MB}MB)"
    fi

    # Create gadget script if it doesn't exist
    if [ ! -f "$GADGET_SCRIPT" ]; then
        log_info "Creating USB gadget configuration script..."
        cat > "$GADGET_SCRIPT" << 'GADGET_EOF'
#!/bin/bash
GADGET_PATH="/sys/kernel/config/usb_gadget/samplepi"
CURRENT_USER=$(whoami)
STORAGE_IMG="/home/$CURRENT_USER/samplepi_media_storage.img"

if [ -d "$GADGET_PATH" ]; then
    echo "USB gadget already configured"
    exit 0
fi

sudo mkdir -p "$GADGET_PATH"
cd "$GADGET_PATH"

echo 0x1d6b | sudo tee idVendor
echo 0x0104 | sudo tee idProduct
echo 0x0100 | sudo tee bcdDevice
echo 0x0200 | sudo tee bcdUSB

sudo mkdir -p strings/0x409
echo "SamplePi" | sudo tee strings/0x409/manufacturer
echo "SamplePi USB Mass Storage" | sudo tee strings/0x409/product
echo "SP123456789" | sudo tee strings/0x409/serialnumber

sudo mkdir -p configs/c.1/strings/0x409
echo "SamplePi Config" | sudo tee configs/c.1/strings/0x409/configuration
echo 250 | sudo tee configs/c.1/MaxPower

sudo mkdir -p functions/mass_storage.usb0
echo "$STORAGE_IMG" | sudo tee functions/mass_storage.usb0/lun.0/file
echo 1 | sudo tee functions/mass_storage.usb0/lun.0/removable
echo "SamplePi Media Storage" | sudo tee functions/mass_storage.usb0/lun.0/inquiry_string

sudo ln -s functions/mass_storage.usb0 configs/c.1/
ls /sys/class/udc | sudo tee UDC

echo "USB Mass Storage Gadget enabled!"
GADGET_EOF
        chmod +x "$GADGET_SCRIPT"
    fi
    
    # Enable and start the gadget service
    systemctl enable "$GADGET_SERVICE" 2>/dev/null || true
    systemctl start "$GADGET_SERVICE" 2>/dev/null || true
    
    # Update SamplePi service to use production media path
    MAIN_SERVICE="/etc/systemd/system/samplepi.service"
    if [ -f "$MAIN_SERVICE" ]; then
        if ! grep -q "MEDIA_PATH_TYPE=production" "$MAIN_SERVICE"; then
            sed -i '/\[Service\]/a Environment="MEDIA_PATH_TYPE=production"' "$MAIN_SERVICE"
            systemctl daemon-reload
        fi
    fi
    
    log_info "USB Gadget Mode ENABLED"
    log_info "Rebooting to activate gadget mode..."
    log_info "After reboot, connect Pi to computer via USB port"
    log_info "Press TOP button (long press) to exit gadget mode"
    
    sleep 2
    reboot
}

# Disable USB gadget mode
disable_gadget_mode() {
    log_info "Disabling USB Gadget Mode..."
    
    # Stop the gadget
    if [ -f "/sys/kernel/config/usb_gadget/samplepi/UDC" ]; then
        echo "" > /sys/kernel/config/usb_gadget/samplepi/UDC 2>/dev/null || true
        log_info "Stopped USB gadget"
    fi
    
    # Disable the service
    systemctl stop "$GADGET_SERVICE" 2>/dev/null || true
    systemctl disable "$GADGET_SERVICE" 2>/dev/null || true
    
    # Remove dwc2 overlay from config.txt
    if grep -q "dtoverlay=dwc2" "$CONFIG_FILE"; then
        sed -i '/dtoverlay=dwc2/d' "$CONFIG_FILE"
        log_info "Removed dwc2 overlay from config.txt"
    fi
    
    # Remove modules-load from cmdline.txt
    CMDLINE_FILE="/boot/cmdline.txt"
    if grep -q "modules-load=dwc2" "$CMDLINE_FILE"; then
        sed -i 's/ modules-load=dwc2,g_mass_storage//' "$CMDLINE_FILE"
        log_info "Removed modules-load from cmdline.txt"
    fi
    
    # Sync any changes from gadget storage back to main directories
    if [ -f "$STORAGE_IMG" ]; then
        log_info "Syncing files from gadget storage..."
        TEMP_MOUNT=$(mktemp -d)
        if mount -o loop "$STORAGE_IMG" "$TEMP_MOUNT" 2>/dev/null; then
            # Copy files from gadget to main media directory
            if [ -d "$TEMP_MOUNT/samples" ]; then
                cp -ru "$TEMP_MOUNT/samples/" "$HOME_DIR/media/samples/" 2>/dev/null || true
            fi
            if [ -d "$TEMP_MOUNT/test_wavs" ]; then
                cp -ru "$TEMP_MOUNT/test_wavs/" "$HOME_DIR/media/test_wavs/" 2>/dev/null || true
            fi
            umount "$TEMP_MOUNT" 2>/dev/null || true
            log_info "Files synced successfully"
        fi
        rmdir "$TEMP_MOUNT" 2>/dev/null || true
    fi
    
    log_info "USB Gadget Mode DISABLED"
    log_info "Rebooting to return to normal mode..."
    log_info "Pico keyboard input will work again after reboot"
    
    sleep 2
    reboot
}

# Main function
main() {
    check_raspberry_pi
    check_root
    
    echo "========================================"
    echo "  SamplePi USB Gadget Mode Toggle"
    echo "========================================"
    echo ""
    
    # Check current state
    if is_gadget_service_enabled || is_gadget_mode; then
        log_info "USB Gadget Mode is currently ENABLED"
        echo ""
        read -p "Do you want to DISABLE gadget mode and return to normal? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            disable_gadget_mode
        else
            log_info "Gadget mode remains enabled"
            exit 0
        fi
    else
        log_info "USB Gadget Mode is currently DISABLED"
        echo ""
        read -p "Do you want to ENABLE gadget mode for file transfer? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            enable_gadget_mode
        else
            log_info "Gadget mode remains disabled"
            exit 0
        fi
    fi
}

# Run main function
main
