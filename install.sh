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
echo "[1/7] Updating system packages..."
sudo apt-get update -qq

# Install system dependencies
echo "[2/7] Installing system dependencies..."
sudo apt-get install -y -qq \
    python3-pip \
    python3-venv \
    python3-lgpio \
    git \
    alsa-utils

# Clone or update repository
INSTALL_DIR="$HOME/SamplePi"
if [ -d "$INSTALL_DIR" ]; then
    echo "[3/7] Updating existing SamplePi installation..."
    cd "$INSTALL_DIR"
    git pull
else
    echo "[3/7] Cloning SamplePi repository..."
    git clone https://github.com/joennespreuwers/SamplePi.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# Create virtual environment
echo "[4/7] Setting up Python virtual environment..."
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi

# Activate virtual environment and install Python packages
echo "[5/7] Installing Python dependencies..."
source .venv/bin/activate
pip install -q --upgrade pip
pip install -q -r requirements.txt

# Enable system packages in venv (for lgpio)
echo "/usr/lib/python3/dist-packages" > .venv/lib/python*/site-packages/system-packages.pth

# Configure HiFiBerry (if not already configured)
echo "[6/7] Configuring HiFiBerry DAC..."
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

# Install systemd service
echo "[7/7] Installing systemd service..."
sed -e "s|%USER%|$USER|g" -e "s|%HOME%|$HOME|g" samplepi.service > /tmp/samplepi.service
sudo mv /tmp/samplepi.service /etc/systemd/system/samplepi.service
sudo systemctl daemon-reload
sudo systemctl enable samplepi.service

# Install desktop autostart (if desktop environment exists)
if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ] || command -v startx &> /dev/null; then
    echo "Installing desktop autostart..."
    mkdir -p "$HOME/.config/autostart"
    sed -e "s|/home/samplepi|$HOME|g" samplepi-autostart.desktop > "$HOME/.config/autostart/samplepi.desktop"
fi

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
