#!/bin/bash
# Touchscreen Calibration Script for SamplePi
# This script helps calibrate the XPT2046 touchscreen on Raspberry Pi

set -e

echo "========================================"
echo "SamplePi Touchscreen Calibration Script"
echo "========================================"
echo ""

# Check if tslib is installed
if ! command -v ts_calibrate &> /dev/null; then
    echo "tslib utilities not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y tslib-calibrate tslib-conf
else
    echo "tslib utilities found."
fi

# Create calibration directory if it doesn't exist
CALIB_DIR="/etc/X11/xorg.conf.d"
sudo mkdir -p "$CALIB_DIR"

# Check for touch device
echo "Looking for touch devices..."
if ls /dev/input/event* 2>/dev/null; then
    for event_dev in /dev/input/event*; do
        # Check if this is a touchscreen device
        if evtest --query "$event_dev" EV_ABS ABS_X ABS_Y 2>/dev/null; then
            echo "Found touch device: $event_dev"
            TOUCH_DEVICE="$event_dev"
            break
        fi
    done
fi

if [ -z "$TOUCH_DEVICE" ]; then
    # Try to find touch device by checking for common touchscreen names
    for event_dev in /dev/input/event*; do
        if [ -e "$event_dev" ]; then
            device_name=$(cat /proc/bus/input/devices 2>/dev/null | grep -A 5 -B 5 "$event_dev" | grep -i "touch\|xpt2046\|ads7846" || true)
            if [ -n "$device_name" ]; then
                echo "Found potential touch device: $event_dev ($device_name)"
                TOUCH_DEVICE="$event_dev"
                break
            fi
        fi
    done
fi

if [ -z "$TOUCH_DEVICE" ]; then
    # Last resort: try to find the device by checking for XPT2046 in device info
    for event_dev in /dev/input/event*; do
        if [ -e "$event_dev" ]; then
            device_info=$(cat /proc/bus/input/devices 2>/dev/null | grep -A 10 -B 10 "XPT2046\|ADS7846" || true)
            if [ -n "$device_info" ]; then
                device_num=$(echo "$device_info" | grep -o "Handlers=.*event[0-9]*" | grep -o "event[0-9]*")
                if [ -n "$device_num" ]; then
                    TOUCH_DEVICE="/dev/input/$device_num"
                    echo "Found XPT2046 touch device: $TOUCH_DEVICE"
                    break
                fi
            fi
        fi
    done
fi

if [ -z "$TOUCH_DEVICE" ]; then
    echo "Could not automatically detect touch device."
    echo "Please manually specify the touch device (e.g., /dev/input/event0):"
    read -p "Touch device path: " TOUCH_DEVICE
    if [ ! -e "$TOUCH_DEVICE" ]; then
        echo "Error: Device $TOUCH_DEVICE does not exist."
        exit 1
    fi
fi

echo ""
echo "Using touch device: $TOUCH_DEVICE"
echo ""

# Create xorg configuration for touchscreen calibration
cat << EOF | sudo tee "$CALIB_DIR/99-touchscreen-calibration.conf"
Section "InputClass"
    Identifier "calibration"
    MatchProduct "ADS7846 Touchscreen"
    Option "Calibration" "3800 200 200 3800"
    Option "SwapAxes" "1"
EndSection

Section "InputClass"
    Identifier "XPT2046 Touchscreen Calibration"
    MatchProduct "XPT2046 Touchscreen"
    Option "Calibration" "3800 200 200 3800"
    Option "SwapAxes" "1"
EndSection
EOF

echo "Created basic xorg calibration configuration."

# Alternative: Create tslib configuration
TS_CONF="/etc/ts.conf"
cat << EOF | sudo tee "$TS_CONF"
module_raw input
module variance delta=30
module dejitter delta=100
module linear
EOF

echo "Created tslib configuration at $TS_CONF"

# Export environment variables for tslib
echo ""
echo "To use tslib calibration, set these environment variables:"
echo "export TSLIB_TSDEVICE=$TOUCH_DEVICE"
echo "export TSLIB_CALIBFILE=/etc/pointercal"
echo "export TSLIB_CONFFILE=/etc/ts.conf"
echo ""

# Run calibration utility if available
if command -v ts_calibrate &> /dev/null; then
    echo "Running touchscreen calibration utility..."
    echo "Follow the on-screen instructions to tap the crosshairs."
    echo ""
    
    # Set environment variables for calibration
    export TSLIB_TSDEVICE="$TOUCH_DEVICE"
    export TSLIB_CALIBFILE="/etc/pointercal"
    export TSLIB_CONFFILE="/etc/ts.conf"
    
    # Create calibration file if it doesn't exist
    sudo touch /etc/pointercal
    
    # Run calibration
    echo "Starting calibration in 3 seconds..."
    sleep 3
    sudo ts_calibrate
    
    echo ""
    echo "Calibration complete! The calibration data is stored in /etc/pointercal"
else
    echo "ts_calibrate not available. You may need to install tslib utilities:"
    echo "sudo apt-get install tslib-calibrate tslib-conf"
fi

echo ""
echo "========================================"
echo "Calibration Complete"
echo "========================================"
echo ""
echo "To test your touchscreen, you can use:"
echo "  - ts_test: Test touch events"
echo "  - export TSLIB_TSDEVICE=$TOUCH_DEVICE && export TSLIB_CALIBFILE=/etc/pointercal && ts_test"
echo ""
echo "For pygame applications, you may need to set:"
echo "  export SDL_MOUSEDEV=$TOUCH_DEVICE"
echo "  export SDL_MOUSEDRV=TSLIB"
echo ""
echo "Reboot recommended to apply all changes: sudo reboot"
echo ""