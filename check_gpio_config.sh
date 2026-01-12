#!/bin/bash
# GPIO Reconfiguration Helper for SamplePi
# This script helps verify and test the new GPIO pin assignments

echo "=========================================="
echo "SamplePi GPIO Reconfiguration Helper"
echo "=========================================="
echo ""

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    echo "Warning: This doesn't appear to be a Raspberry Pi"
    echo "Some GPIO functions may not work properly"
fi

echo "Current GPIO Pin Configuration:"
echo "--------------------------------"
echo "Rotary Encoder:"
echo "  - CLK: GPIO 12 (Physical Pin 32)"
echo "  - DT:  GPIO 13 (Physical Pin 33)" 
echo "  - SW:  GPIO 16 (Physical Pin 36)"
echo ""
echo "Physical Buttons (Left Side):"
echo "  - Top:    GPIO 5 (Physical Pin 29)"
echo "  - Middle: GPIO 6 (Physical Pin 31)"
echo "  - Bottom: GPIO 19 (Physical Pin 35)"
echo ""
echo "Other GPIO:"
echo "  - Camera Trigger: GPIO 26 (Physical Pin 37)"
echo ""

# Check if gpio command is available
if command -v gpio &> /dev/null; then
    echo "Testing GPIO access..."
    echo "Checking if user has GPIO permissions:"
    
    # Test access to a few pins
    TEST_PINS=(12 13 16 5 6 19 26)
    ACCESSIBLE_PINS=()
    
    for pin in "${TEST_PINS[@]}"; do
        if [ -e "/sys/class/gpio/gpio$pin" ] || (gpio read $pin &>/dev/null && echo $?); then
            ACCESSIBLE_PINS+=("$pin")
        fi
    done
    
    if [ ${#ACCESSIBLE_PINS[@]} -gt 0 ]; then
        echo "  ✓ GPIO access available for pins: ${ACCESSIBLE_PINS[*]}"
    else
        echo "  ⚠ GPIO access may be restricted"
        echo "  Run: sudo usermod -a -G gpio $USER"
        echo "  Then log out and back in"
    fi
else
    echo "  ! WiringPi/gpio utility not found"
    echo "  Install with: sudo apt-get install wiringpi"
fi

echo ""
echo "SPI Bus Check:"
echo "-------------"
if ls /dev/spi* &> /dev/null; then
    echo "  ✓ SPI devices found: $(ls /dev/spi*)"
    echo "  This indicates SPI is enabled for display"
else
    echo "  ⚠ No SPI devices found"
    echo "  Check if SPI is enabled in raspi-config"
fi

echo ""
echo "I2C Bus Check:" 
echo "-------------"
if command -v i2cdetect &> /dev/null; then
    if i2cdetect -y 1 &>/dev/null; then
        echo "  ✓ I2C bus available (may be used by touch controller)"
    else
        echo "  - I2C bus not responding"
    fi
else
    echo "  ! i2cdetect not available (install with: sudo apt-get install i2c-tools)"
fi

echo ""
echo "Configuration Verification:"
echo "--------------------------"
echo "1. Verify rotary encoder is connected to:"
echo "   - GPIO 12 (Physical Pin 32) - CLK"
echo "   - GPIO 13 (Physical Pin 33) - DT" 
echo "   - GPIO 16 (Physical Pin 36) - SW"
echo ""
echo "2. Verify physical buttons are connected to:"
echo "   - GPIO 5 (Physical Pin 29) - Top"
echo "   - GPIO 6 (Physical Pin 31) - Middle"
echo "   - GPIO 19 (Physical Pin 35) - Bottom"
echo ""
echo "3. Verify camera trigger is connected to:"
echo "   - GPIO 26 (Physical Pin 37)"
echo ""

echo "To test the SamplePi application with new configuration:"
echo "  cd ~/SamplePi"
echo "  source .venv/bin/activate"
echo "  python3 -m samplepi.main"
echo ""

echo "=========================================="
echo "Reconfiguration Helper Complete"
echo "=========================================="