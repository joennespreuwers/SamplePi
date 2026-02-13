#!/bin/bash

# Test script for SamplePi USB Gadget functionality
# This script tests various aspects of the USB gadget implementation

echo "=== SamplePi USB Gadget Test Script ==="
echo

# Test 1: Check if required files exist
echo "Test 1: Checking for required files..."
REQUIRED_FILES=(
    "setup_usb_gadget.sh"
    "sync_gadget_storage.sh"
    "autosync_service.sh"
    "debug_gadget.sh"
    "samplepi-gadget-sync.service"
)

ALL_PRESENT=true
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file exists"
    else
        echo "  ✗ $file missing"
        ALL_PRESENT=false
    fi
done

if [ "$ALL_PRESENT" = true ]; then
    echo "  All required files are present"
else
    echo "  Some required files are missing"
    exit 1
fi

echo

# Test 2: Check if scripts are executable
echo "Test 2: Checking script permissions..."
SCRIPTS=("setup_usb_gadget.sh" "sync_gadget_storage.sh" "autosync_service.sh" "debug_gadget.sh")

for script in "${SCRIPTS[@]}"; do
    if [ -x "$script" ]; then
        echo "  ✓ $script is executable"
    else
        echo "  ⚠ $script is not executable, attempting to fix..."
        chmod +x "$script"
        if [ $? -eq 0 ]; then
            echo "    Fixed permissions for $script"
        else
            echo "    Failed to fix permissions for $script"
        fi
    fi
done

echo

# Test 3: Check if configuration is syntactically correct
echo "Test 3: Checking script syntax..."
for script in "${SCRIPTS[@]}"; do
    if bash -n "$script"; then
        echo "  ✓ $script syntax is valid"
    else
        echo "  ✗ $script has syntax errors"
        ALL_PRESENT=false
    fi
done

echo

# Test 4: Check if Python configuration is correct
echo "Test 4: Checking Python configuration..."
if python3 -c "import sys; sys.path.insert(0, '../'); from samplepi.config.settings import *; print('Media root:', MEDIA_ROOT if 'MEDIA_PATH_TYPE' not in __import__('os').environ or __import__('os').environ.get('MEDIA_PATH_TYPE') != 'production' else '/home/pi/media')" &>/dev/null; then
    echo "  ✓ Python configuration is valid"
else
    echo "  ✗ Python configuration has errors"
    ALL_PRESENT=false
fi

echo

# Test 5: Check if service file has correct format
echo "Test 5: Checking service file format..."
if grep -q "\[Unit\]" "samplepi-gadget-sync.service" && grep -q "\[Service\]" "samplepi-gadget-sync.service" && grep -q "\[Install\]" "samplepi-gadget-sync.service"; then
    echo "  ✓ samplepi-gadget-sync.service has correct format"
else
    echo "  ✗ samplepi-gadget-sync.service format is incorrect"
    ALL_PRESENT=false
fi

echo

if [ "$ALL_PRESENT" = true ]; then
    echo "✓ All tests passed! USB gadget implementation appears to be complete."
    echo
    echo "To fully test the functionality, deploy to a Raspberry Pi and run:"
    echo "  1. ./setup_usb_gadget.sh"
    echo "  2. sudo reboot"
    echo "  3. Connect to a computer via USB to verify mass storage functionality"
    echo "  4. Use ./debug_gadget.sh to check status"
else
    echo "✗ Some tests failed. Please review the errors above."
    exit 1
fi

echo
echo "=== Test Complete ==="