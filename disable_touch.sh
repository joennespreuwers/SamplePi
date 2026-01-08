#!/bin/bash
# Disable XPT2046 Touch Controller
# This frees up GPIO pins for rotary encoder and prevents conflicts

set -e

CONFIG_FILE="/boot/firmware/config.txt"
if [ ! -f "$CONFIG_FILE" ]; then
    CONFIG_FILE="/boot/config.txt"
fi

echo "========================================"
echo "Disabling XPT2046 Touch Controller"
echo "========================================"
echo ""

# Backup config file
echo "Creating backup: ${CONFIG_FILE}.backup"
sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"

# Remove any touch-related overlays
echo "Removing touch controller overlays..."
sudo sed -i '/dtoverlay=ads7846/d' "$CONFIG_FILE"
sudo sed -i '/dtoverlay=xpt2046/d' "$CONFIG_FILE"

# If using waveshare32b, we need to modify it to disable touch
if grep -q "dtoverlay=waveshare32b" "$CONFIG_FILE"; then
    echo "Found waveshare32b overlay - disabling touch component..."
    # Comment out waveshare32b and use custom config
    sudo sed -i 's/^dtoverlay=waveshare32b/#dtoverlay=waveshare32b (disabled - using custom below)/' "$CONFIG_FILE"

    # Add custom display-only configuration
    if ! grep -q "# Display only - no touch" "$CONFIG_FILE"; then
        cat << 'EOF' | sudo tee -a "$CONFIG_FILE"

# Display only - no touch (XPT2046 disabled)
dtparam=spi=on
dtoverlay=waveshare32b:disable_touch
EOF
    fi
fi

# Check if there are any modules loading touch drivers
MODULES_FILE="/etc/modules"
if [ -f "$MODULES_FILE" ]; then
    echo "Checking $MODULES_FILE for touch drivers..."
    if grep -q "ads7846\|xpt2046" "$MODULES_FILE"; then
        echo "Removing touch drivers from modules..."
        sudo sed -i '/ads7846/d' "$MODULES_FILE"
        sudo sed -i '/xpt2046/d' "$MODULES_FILE"
    fi
fi

# Blacklist touch modules to prevent loading
BLACKLIST_FILE="/etc/modprobe.d/touchscreen-blacklist.conf"
echo "Creating touchscreen module blacklist..."
cat << 'EOF' | sudo tee "$BLACKLIST_FILE"
# Blacklist XPT2046/ADS7846 touch controller modules
# This frees up GPIO pins for other uses (rotary encoder)
blacklist ads7846
blacklist xpt2046
EOF

echo ""
echo "✓ Touch controller disabled successfully!"
echo ""
echo "Freed GPIO pins (typical XPT2046 usage):"
echo "  - T_IRQ: Usually GPIO 17 or 25"
echo "  - SPI pins remain for display"
echo ""
echo "Your rotary encoder pins are now safe:"
echo "  - GPIO 17 (CLK) - No conflict"
echo "  - GPIO 27 (DT)  - No conflict"
echo "  - GPIO 22 (SW)  - No conflict"
echo ""
echo "Configuration backed up to: ${CONFIG_FILE}.backup"
echo ""
echo "⚠️  REBOOT REQUIRED for changes to take effect"
echo ""
read -p "Reboot now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    sudo reboot
else
    echo "Remember to reboot later: sudo reboot"
fi
