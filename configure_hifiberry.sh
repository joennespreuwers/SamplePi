#!/bin/bash
# HiFiBerry DAC Auto-Detection and Configuration
# Detects HiFiBerry DAC and configures it automatically

echo "========================================"
echo "HiFiBerry DAC Configuration Tool"
echo "========================================"
echo ""

# Check if running on Raspberry Pi
if [ ! -f /proc/device-tree/model ]; then
    echo "Warning: This script is designed for Raspberry Pi"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

CONFIG_FILE="/boot/firmware/config.txt"
if [ ! -f "$CONFIG_FILE" ]; then
    CONFIG_FILE="/boot/config.txt"
fi

echo "[1/4] Checking for HiFiBerry hardware..."
echo ""

# Check I2C for DAC chip
HIFIBERRY_DETECTED=false
DAC_TYPE="unknown"

if command -v i2cdetect &> /dev/null; then
    # Check for common DAC chips
    # PCM512x chips are at address 0x4c or 0x4d
    I2C_OUTPUT=$(sudo i2cdetect -y 1 2>/dev/null)

    if echo "$I2C_OUTPUT" | grep -q " 4c "; then
        HIFIBERRY_DETECTED=true
        DAC_TYPE="dacplus"
        echo "  ✓ HiFiBerry DAC+ detected (PCM512x at 0x4c)"
    elif echo "$I2C_OUTPUT" | grep -q " 4d "; then
        HIFIBERRY_DETECTED=true
        DAC_TYPE="dacplus"
        echo "  ✓ HiFiBerry DAC+ detected (PCM512x at 0x4d)"
    else
        echo "  ? No HiFiBerry DAC chip detected on I2C bus"
        echo "    (This is normal if DAC is not yet configured)"
    fi
else
    echo "  ! i2c-tools not installed"
    echo "    Installing: sudo apt-get install -y i2c-tools"
    sudo apt-get install -y i2c-tools
fi

echo ""
echo "[2/4] Checking current configuration..."
echo ""

if [ -f "$CONFIG_FILE" ]; then
    echo "Audio settings in $CONFIG_FILE:"
    echo ""

    # Check for existing HiFiBerry config
    if grep -q "dtoverlay=hifiberry" "$CONFIG_FILE"; then
        echo "  ✓ HiFiBerry overlay already configured:"
        grep "dtoverlay=hifiberry" "$CONFIG_FILE" | grep -v "^#"
    else
        echo "  ✗ No HiFiBerry overlay found"
    fi

    # Check if onboard audio is disabled
    if grep -q "^dtparam=audio=off" "$CONFIG_FILE"; then
        echo "  ✓ Onboard audio disabled"
    elif grep -q "^dtparam=audio=on" "$CONFIG_FILE"; then
        echo "  ! Onboard audio is enabled (should be disabled for HiFiBerry)"
    else
        echo "  ? Onboard audio setting not found"
    fi
else
    echo "  ✗ Config file not found: $CONFIG_FILE"
    exit 1
fi

echo ""
echo "[3/4] Configuration options..."
echo ""

# Determine which DAC model to configure
echo "Select your HiFiBerry model:"
echo "  1) HiFiBerry DAC+ (most common)"
echo "  2) HiFiBerry DAC2 HD"
echo "  3) HiFiBerry DAC+ Pro"
echo "  4) HiFiBerry DAC Zero"
echo "  5) Skip configuration"
echo ""
read -p "Enter choice [1-5]: " choice

case $choice in
    1)
        OVERLAY="hifiberry-dacplus"
        echo "Selected: HiFiBerry DAC+"
        ;;
    2)
        OVERLAY="hifiberry-dacplushd"
        echo "Selected: HiFiBerry DAC2 HD"
        ;;
    3)
        OVERLAY="hifiberry-dacplusadcpro"
        echo "Selected: HiFiBerry DAC+ Pro"
        ;;
    4)
        OVERLAY="hifiberry-dac"
        echo "Selected: HiFiBerry DAC Zero"
        ;;
    5)
        echo "Skipping configuration"
        exit 0
        ;;
    *)
        echo "Invalid choice, defaulting to HiFiBerry DAC+"
        OVERLAY="hifiberry-dacplus"
        ;;
esac

echo ""
echo "[4/4] Applying configuration..."
echo ""

# Backup config file
echo "Creating backup: ${CONFIG_FILE}.backup"
sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"

# Remove old HiFiBerry overlays
sudo sed -i '/dtoverlay=hifiberry/d' "$CONFIG_FILE"

# Disable onboard audio
if grep -q "^dtparam=audio" "$CONFIG_FILE"; then
    sudo sed -i 's/^dtparam=audio=on/dtparam=audio=off/' "$CONFIG_FILE"
else
    # Add to the file
    echo "dtparam=audio=off" | sudo tee -a "$CONFIG_FILE" > /dev/null
fi

# Add HiFiBerry overlay
echo "dtoverlay=$OVERLAY" | sudo tee -a "$CONFIG_FILE" > /dev/null

echo "  ✓ Configuration updated"
echo ""

# Configure ALSA
echo "Configuring ALSA..."
ALSA_CONF="/etc/asound.conf"

sudo tee "$ALSA_CONF" > /dev/null <<EOF
pcm.!default {
  type hw
  card 0
}

ctl.!default {
  type hw
  card 0
}
EOF

echo "  ✓ ALSA configured"
echo ""

echo "========================================"
echo "Configuration Complete!"
echo "========================================"
echo ""
echo "Changes made:"
echo "  - Disabled onboard audio (dtparam=audio=off)"
echo "  - Added HiFiBerry overlay (dtoverlay=$OVERLAY)"
echo "  - Configured ALSA to use HiFiBerry as default"
echo "  - Backup saved: ${CONFIG_FILE}.backup"
echo ""
echo "IMPORTANT: You must reboot for changes to take effect!"
echo ""
read -p "Reboot now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    sudo reboot
else
    echo ""
    echo "Remember to reboot later: sudo reboot"
    echo ""
    echo "After reboot, verify with:"
    echo "  aplay -l        # Should show HiFiBerry as card 0"
    echo "  speaker-test -c 2    # Test audio output"
fi
