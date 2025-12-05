#!/bin/bash
# SamplePi One-Command Installer
# Run with: curl -fsSL https://raw.githubusercontent.com/joennespreuwers/SamplePi/main/install.sh | bash

set -e

echo "========================================="
echo "SamplePi Installer"
echo "========================================="
echo ""

# Detect if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    echo "Warning: This doesn't appear to be a Raspberry Pi"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update system
echo "[1/9] Updating system packages..."
sudo apt-get update -qq

# Install system dependencies
echo "[2/9] Installing system dependencies..."
sudo apt-get install -y -qq \
    python3-pip \
    python3-venv \
    python3-lgpio \
    git \
    alsa-utils \
    unzip \
    cmake

# Configure Waveshare 3.2" LCD
echo "[3/9] Configuring Waveshare 3.2\" LCD display..."
if [ ! -f /boot/overlays/waveshare32b.dtbo ]; then
    cd /tmp
    sudo wget -q https://files.waveshare.com/wiki/common/Waveshare32b.zip
    sudo unzip -q -o ./Waveshare32b.zip
    sudo cp waveshare32b.dtbo /boot/overlays/
    sudo rm -f Waveshare32b.zip waveshare32b.dtbo
    echo "Waveshare display driver installed"
fi

# Configure display in config.txt
if ! grep -q "dtoverlay=waveshare32b" /boot/firmware/config.txt 2>/dev/null; then
    echo "Configuring display settings in config.txt..."

    # Comment out vc4-kms-v3d if present
    sudo sed -i 's/^dtoverlay=vc4-kms-v3d/#dtoverlay=vc4-kms-v3d/' /boot/firmware/config.txt

    # Add Waveshare display configuration
    cat << 'EOF' | sudo tee -a /boot/firmware/config.txt

# Waveshare 3.2" LCD Configuration (320x240)
dtparam=spi=on
dtoverlay=waveshare32b
hdmi_force_hotplug=1
max_usb_current=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt 320 240 60 6 0 0 0
hdmi_drive=2
display_rotate=0
EOF
    echo "Display configuration added to config.txt"
fi

# Clone or update repository
INSTALL_DIR="$HOME/SamplePi"
if [ -d "$INSTALL_DIR" ]; then
    echo "[4/9] Updating existing SamplePi installation..."
    cd "$INSTALL_DIR"
    git pull
else
    echo "[4/9] Cloning SamplePi repository..."
    git clone https://github.com/joennespreuwers/SamplePi.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# Create virtual environment
echo "[5/9] Setting up Python virtual environment..."
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi

# Activate virtual environment and install Python packages
echo "[6/9] Installing Python dependencies..."
source .venv/bin/activate
pip install -q --upgrade pip
pip install -q -r requirements.txt

# Enable system packages in venv (for lgpio)
SITE_PACKAGES=$(find .venv/lib -type d -name "site-packages" | head -n 1)
echo "/usr/lib/python3/dist-packages" > "$SITE_PACKAGES/system-packages.pth"

# Configure HiFiBerry (if not already configured)
echo "[7/9] Configuring HiFiBerry DAC..."
if ! grep -q "dtoverlay=hifiberry-dacplus" /boot/firmware/config.txt 2>/dev/null; then
    echo "dtoverlay=hifiberry-dacplus" | sudo tee -a /boot/firmware/config.txt
    echo "HiFiBerry configuration added to config.txt"
fi

# Set HiFiBerry as default audio device
if [ ! -f /etc/asound.conf ]; then
    echo "Setting HiFiBerry as default audio device..."
    cat << 'EOF' | sudo tee /etc/asound.conf
pcm.!default {
    type hw
    card sndrpihifiberry
}

ctl.!default {
    type hw
    card sndrpihifiberry
}
EOF
fi

# Configure X11 for framebuffer display
echo "[8/9] Configuring X11 for LCD display..."
sudo mkdir -p /usr/share/X11/xorg.conf.d
if [ ! -f /usr/share/X11/xorg.conf.d/99-fbturbo.conf ]; then
    cat << 'EOF' | sudo tee /usr/share/X11/xorg.conf.d/99-fbturbo.conf
Section "Device"
        Identifier      "Allwinner A10/A13 FBDEV"
        Driver          "fbturbo"
        Option          "fbdev" "/dev/fb0"
        Option          "SwapbuffersWait" "true"
EndSection
EOF
    echo "X11 framebuffer configuration created"
fi

# Configure auto-login and startx
echo "Configuring auto-login and X11 autostart..."

# Set CLI auto-login
sudo raspi-config nonint do_boot_behaviour B2
sudo raspi-config nonint do_wayland W1

# Add startx to .bash_profile if not already present
if ! grep -q "startx" "$HOME/.bash_profile" 2>/dev/null; then
    cat << 'EOF' >> "$HOME/.bash_profile"
export FRAMEBUFFER=/dev/fb1
startx 2> /tmp/xorg_errors
EOF
    echo "Auto-startx configured in .bash_profile"
fi

# Install systemd service
echo "[9/9] Installing systemd service..."
sed -e "s|%USER%|$USER|g" -e "s|%HOME%|$HOME|g" samplepi.service > /tmp/samplepi.service
sudo mv /tmp/samplepi.service /etc/systemd/system/samplepi.service
sudo systemctl daemon-reload
sudo systemctl enable samplepi.service

# Install desktop autostart
echo "Installing desktop autostart..."
mkdir -p "$HOME/.config/autostart"
sed -e "s|/home/samplepi|$HOME|g" samplepi-autostart.desktop > "$HOME/.config/autostart/samplepi.desktop"

echo ""
echo "========================================="
echo "Installation Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Reboot to apply audio configuration:"
echo "   sudo reboot"
echo ""
echo "2. After reboot, the service will start automatically"
echo ""
echo "Manual control:"
echo "  Start:   sudo systemctl start samplepi"
echo "  Stop:    sudo systemctl stop samplepi"
echo "  Status:  sudo systemctl status samplepi"
echo "  Logs:    sudo journalctl -u samplepi -f"
echo ""
echo "Test manually (in desktop mode):"
echo "  cd $INSTALL_DIR"
echo "  source .venv/bin/activate"
echo "  python3 -m samplepi.main"
echo ""
echo "Configuration files:"
echo "  Audio/GPIO settings: $INSTALL_DIR/samplepi/config/settings.py"
echo "  Media directory: $INSTALL_DIR/test_media/"
echo ""
