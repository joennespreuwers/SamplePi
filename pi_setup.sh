#!/bin/bash
# Raspberry Pi Setup Script for SamplePi
# Run this script on your Raspberry Pi to set up the SamplePi system

set -e  # Exit on error

echo "====================================="
echo "SamplePi - Raspberry Pi Setup"
echo "====================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
   echo "Please do not run as root. Run as the pi user."
   exit 1
fi

# Update system
echo "[1/8] Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install dependencies
echo "[2/8] Installing system dependencies..."
sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    git \
    libsdl2-dev \
    libsdl2-image-dev \
    libsdl2-mixer-dev \
    libsdl2-ttf-dev \
    libfreetype6-dev \
    libportmidi-dev \
    libjpeg-dev \
    python3-setuptools \
    python3-numpy

# Install RPi.GPIO and gpiozero
echo "[3/8] Installing GPIO libraries..."
sudo apt-get install -y python3-gpiozero python3-rpi.gpio

# Create project directory
echo "[4/8] Setting up project directory..."
PROJECT_DIR="$HOME/SamplePi"
if [ ! -d "$PROJECT_DIR" ]; then
    mkdir -p "$PROJECT_DIR"
fi
cd "$PROJECT_DIR"

# Create virtual environment
echo "[5/8] Creating Python virtual environment..."
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi

# Activate virtual environment and install Python packages
echo "[6/8] Installing Python packages..."
source .venv/bin/activate
pip install --upgrade pip
pip install pygame gpiozero RPi.GPIO

# Create media directories
echo "[7/8] Creating media directories..."
MEDIA_DIR="$HOME/media"
sudo mkdir -p "$MEDIA_DIR/test_wavs"
sudo mkdir -p "$MEDIA_DIR/samples"
sudo chown -R $USER:$USER "$MEDIA_DIR"
chmod -R 755 "$MEDIA_DIR"

# Install systemd service
echo "[8/8] Installing systemd service..."
if [ -f "samplepi.service" ]; then
    # Create service file with current user and home directory
    sed -e "s|%USER%|$USER|g" -e "s|%HOME%|$HOME|g" samplepi.service > /tmp/samplepi.service
    sudo mv /tmp/samplepi.service /etc/systemd/system/samplepi.service
    sudo systemctl daemon-reload
    sudo systemctl enable samplepi.service
    echo "Systemd service installed and enabled for user: $USER"
else
    echo "Warning: samplepi.service file not found. Skipping service installation."
fi

echo ""
echo "====================================="
echo "Setup Complete!"
echo "====================================="
echo ""
echo "Next steps:"
echo "1. Copy your WAV files to $MEDIA_DIR/test_wavs/ and $MEDIA_DIR/samples/"
echo "2. Update samplepi/config/settings.py to use MEDIA_ROOT = '$MEDIA_DIR'"
echo "3. Configure HiFiBerry DAC (see RASPBERRY_PI_SETUP.md)"
echo "4. Start the service: sudo systemctl start samplepi"
echo "5. Check status: sudo systemctl status samplepi"
echo "6. View logs: sudo journalctl -u samplepi -f"
echo ""
