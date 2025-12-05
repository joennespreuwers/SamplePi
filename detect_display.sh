#!/bin/bash
# Display Detection and Configuration Helper
# This script helps identify and configure your display on Raspberry Pi

echo "========================================"
echo "Display Detection & Configuration Tool"
echo "========================================"
echo ""

# Check if running on Raspberry Pi
if [ ! -f /proc/device-tree/model ]; then
    echo "Warning: This script is designed for Raspberry Pi"
    echo "Continuing anyway..."
fi

# Function to detect display type
detect_display() {
    echo "[1/5] Detecting display hardware..."
    echo ""

    # Check for I2C displays
    if command -v i2cdetect &> /dev/null; then
        echo "Scanning I2C bus for displays..."
        i2c_devices=$(sudo i2cdetect -y 1 2>/dev/null | grep -v "^[0-9]" | grep -oE "[0-9a-f]{2}" | wc -l)
        if [ "$i2c_devices" -gt 0 ]; then
            echo "  ✓ Found I2C devices (count: $i2c_devices)"
            sudo i2cdetect -y 1
        else
            echo "  ✗ No I2C displays detected"
        fi
    else
        echo "  ! i2c-tools not installed (run: sudo apt-get install i2c-tools)"
    fi

    echo ""

    # Check for SPI displays
    if [ -d /sys/class/spi_master ]; then
        echo "Checking SPI displays..."
        if ls /sys/class/spi_master/*/device/spi* &> /dev/null; then
            echo "  ✓ SPI devices detected"
            ls -l /sys/class/spi_master/*/device/spi*
        else
            echo "  ✗ No SPI displays detected"
        fi
    fi

    echo ""

    # Check framebuffer devices
    echo "Checking framebuffer devices..."
    if ls /dev/fb* &> /dev/null; then
        echo "  ✓ Framebuffer devices found:"
        for fb in /dev/fb*; do
            echo "    - $fb"
            if [ -r "$fb" ]; then
                fbinfo=$(cat /sys/class/graphics/$(basename $fb)/name 2>/dev/null)
                echo "      Type: ${fbinfo:-Unknown}"
            fi
        done
    else
        echo "  ✗ No framebuffer devices found"
    fi
}

# Function to list available display overlays
list_overlays() {
    echo ""
    echo "[2/5] Available display overlays..."
    echo ""

    if command -v dtoverlay &> /dev/null; then
        echo "Common display overlays:"
        echo ""
        dtoverlay -a | grep -E "waveshare|lcd|tft|ili|st7789|ssd1306|xpt2046" | head -20
        echo ""
        echo "For full list: dtoverlay -a | grep -i display"
    else
        echo "dtoverlay command not available"
    fi
}

# Function to check current configuration
check_config() {
    echo ""
    echo "[3/5] Checking current configuration..."
    echo ""

    CONFIG_FILE="/boot/firmware/config.txt"
    if [ ! -f "$CONFIG_FILE" ]; then
        CONFIG_FILE="/boot/config.txt"
    fi

    if [ -f "$CONFIG_FILE" ]; then
        echo "Display-related settings in $CONFIG_FILE:"
        echo ""
        grep -E "dtoverlay.*=.*(lcd|tft|waveshare|display)|hdmi_|display_" "$CONFIG_FILE" | grep -v "^#" || echo "  (No display settings found)"
        echo ""
    else
        echo "Config file not found at $CONFIG_FILE"
    fi
}

# Function to suggest configuration
suggest_config() {
    echo ""
    echo "[4/5] Configuration suggestions..."
    echo ""

    echo "Based on your hardware (3.21\" XPT2046 touchscreen), you likely need:"
    echo ""
    echo "Option 1: Waveshare 3.2\" display"
    echo "  Add to $CONFIG_FILE:"
    echo "  dtoverlay=waveshare32b"
    echo "  dtparam=speed=20000000"
    echo "  dtparam=rotate=270"
    echo ""
    echo "Option 2: Generic SPI display with XPT2046 touch"
    echo "  Add to $CONFIG_FILE:"
    echo "  dtoverlay=piscreen"
    echo "  dtoverlay=piscreen,speed=16000000,rotate=90"
    echo ""
    echo "Option 3: Custom HDMI timing (if using HDMI)"
    echo "  Add to $CONFIG_FILE:"
    echo "  hdmi_force_hotplug=1"
    echo "  hdmi_cvt=480 320 60 1 0 0 0"
    echo "  hdmi_group=2"
    echo "  hdmi_mode=87"
    echo ""
    echo "Also add to /boot/firmware/cmdline.txt (or /boot/cmdline.txt):"
    echo "  consoleblank=0"
    echo ""
}

# Function to test display
test_display() {
    echo ""
    echo "[5/5] Display testing..."
    echo ""

    if [ -e /dev/fb0 ]; then
        echo "Testing framebuffer /dev/fb0..."

        # Check if fbi is installed
        if command -v fbi &> /dev/null; then
            echo "  ✓ fbi tool available"
            echo ""
            echo "To test your display, run:"
            echo "  sudo fbi -T 1 -d /dev/fb0 /path/to/image.png"
        else
            echo "  ! fbi not installed"
            echo "  Install: sudo apt-get install fbi"
        fi

        echo ""
        echo "Or test with SamplePi:"
        echo "  cd $HOME/SamplePi"
        echo "  SDL_VIDEODRIVER=fbcon SDL_FBDEV=/dev/fb0 python3 -m samplepi.main"
    else
        echo "  ✗ /dev/fb0 not found - display not configured yet"
    fi
}

# Main execution
detect_display
list_overlays
check_config
suggest_config
test_display

echo ""
echo "========================================"
echo "Detection Complete"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Edit /boot/firmware/config.txt (or /boot/config.txt) with suggested overlay"
echo "2. Reboot: sudo reboot"
echo "3. Re-run this script to verify configuration"
echo "4. Test with: sudo fbi -T 1 -d /dev/fb0 image.png"
echo ""
