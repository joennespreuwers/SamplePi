#!/bin/bash

# USB Gadget Mode Toggle - Interactive version for manual use via SSH
# Wraps toggle_gadget_button.sh with user prompts and state display.
# For non-interactive (button press) use, call toggle_gadget_button.sh directly.

set -e

# Get the actual user even when run via sudo
CURRENT_USER="${SUDO_USER:-$(logname 2>/dev/null || whoami)}"
HOME_DIR=$(getent passwd "$CURRENT_USER" | cut -d: -f6)
GADGET_PATH="/sys/kernel/config/usb_gadget/samplepi"

# Detect boot config location (Pi OS Bookworm uses /boot/firmware/)
if [ -f "/boot/firmware/config.txt" ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
else
    CONFIG_FILE="/boot/config.txt"
fi

# Find the non-interactive toggle script
TOGGLE_SCRIPT="$HOME_DIR/SamplePi/usb_gadget/toggle_gadget_button.sh"
if [ ! -f "$TOGGLE_SCRIPT" ]; then
    TOGGLE_SCRIPT="/usr/local/bin/samplepi_toggle_gadget.sh"
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_raspberry_pi() {
    if ! [ -f /proc/device-tree/model ]; then
        echo -e "${RED}[ERROR]${NC} This script is intended to run on a Raspberry Pi"
        exit 1
    fi
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[ERROR]${NC} This script must be run as root: sudo $0"
        exit 1
    fi
}

check_setup() {
    if ! grep -q "dtoverlay=dwc2" "$CONFIG_FILE" 2>/dev/null; then
        echo -e "${YELLOW}[WARN]${NC} dtoverlay=dwc2 not found in $CONFIG_FILE"
        echo "  Run setup_usb_gadget.sh first for one-time hardware setup (requires one reboot)."
        exit 1
    fi
    if [ ! -f "$TOGGLE_SCRIPT" ]; then
        echo -e "${RED}[ERROR]${NC} Toggle script not found at $TOGGLE_SCRIPT"
        echo "  Run setup_usb_gadget.sh to install it."
        exit 1
    fi
}

is_gadget_active() {
    [ -d "$GADGET_PATH" ] && \
    [ -f "$GADGET_PATH/UDC" ] && \
    [ -s "$GADGET_PATH/UDC" ]
}

main() {
    check_raspberry_pi
    check_root
    check_setup

    echo "========================================"
    echo "  SamplePi USB Gadget Mode Toggle"
    echo "========================================"
    echo ""

    if is_gadget_active; then
        echo -e "${GREEN}[INFO]${NC} USB Gadget Mode is currently ENABLED"
        echo ""
        read -p "Disable gadget mode and sync files back? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            "$TOGGLE_SCRIPT"
            echo -e "${GREEN}[INFO]${NC} Done. USB Gadget Mode disabled."
        else
            echo -e "${GREEN}[INFO]${NC} Gadget mode remains enabled."
        fi
    else
        echo -e "${GREEN}[INFO]${NC} USB Gadget Mode is currently DISABLED"
        echo ""
        read -p "Enable gadget mode for file transfer? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            "$TOGGLE_SCRIPT"
            echo -e "${GREEN}[INFO]${NC} Done. Connect Pi to computer via USB."
            echo "  Long-press TOP button again to disable."
        else
            echo -e "${GREEN}[INFO]${NC} Gadget mode remains disabled."
        fi
    fi
}

main
