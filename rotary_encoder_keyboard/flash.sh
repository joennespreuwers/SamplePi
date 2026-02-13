#!/bin/bash

# Flash script for Raspberry Pi Pico
# Run this after putting your Pico into bootloader mode (hold BOOTSEL while plugging in)

echo "Looking for RPI-RP2 drive..."

# Wait for the drive to appear (max 10 seconds)
for i in {1..10}; do
    if [ -d "/Volumes/RPI-RP2" ]; then
        echo "✓ Found RPI-RP2 drive"
        echo "Copying firmware..."
        cp build/rotary_encoder_keyboard.ino.uf2 /Volumes/RPI-RP2/
        echo "✓ Firmware copied successfully!"
        echo "The Pico will automatically reboot and start working as a keyboard."
        exit 0
    fi
    echo "Waiting for RPI-RP2 drive... ($i/10)"
    sleep 1
done

echo "✗ Error: RPI-RP2 drive not found"
echo ""
echo "Please make sure to:"
echo "  1. Hold the BOOTSEL button on your Pico"
echo "  2. Plug in the USB cable while holding BOOTSEL"
echo "  3. Release the BOOTSEL button"
echo "  4. Run this script again"
exit 1
