#!/bin/bash
# Hardware Testing and Verification Script
# Tests all SamplePi hardware components

echo "========================================"
echo "SamplePi Hardware Test Suite"
echo "========================================"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test result counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Helper functions
pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((TESTS_FAILED++))
}

skip() {
    echo -e "${YELLOW}⊘ SKIP${NC}: $1"
    ((TESTS_SKIPPED++))
}

info() {
    echo -e "  ℹ $1"
}

# Test 1: System Information
test_system() {
    echo "[Test 1/7] System Information"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ -f /proc/device-tree/model ]; then
        MODEL=$(cat /proc/device-tree/model)
        pass "Raspberry Pi detected: $MODEL"
    else
        skip "Not running on Raspberry Pi"
    fi

    info "Kernel: $(uname -r)"
    info "Python: $(python3 --version 2>&1)"
    echo ""
}

# Test 2: GPIO Access
test_gpio() {
    echo "[Test 2/7] GPIO Access"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check GPIO group membership
    if groups | grep -q gpio; then
        pass "User in gpio group"
    else
        fail "User not in gpio group (run: sudo usermod -a -G gpio $USER)"
    fi

    # Check gpiozero
    if python3 -c "import gpiozero" 2>/dev/null; then
        pass "gpiozero library installed"
    else
        fail "gpiozero not installed (run: pip install gpiozero)"
    fi

    # Check RPi.GPIO
    if python3 -c "import RPi.GPIO" 2>/dev/null; then
        pass "RPi.GPIO library installed"
    else
        fail "RPi.GPIO not installed (run: pip install RPi.GPIO)"
    fi

    echo ""
}

# Test 3: Display
test_display() {
    echo "[Test 3/7] Display"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check framebuffer
    if [ -e /dev/fb0 ]; then
        pass "Framebuffer device exists (/dev/fb0)"

        # Check framebuffer permissions
        if [ -r /dev/fb0 ] && [ -w /dev/fb0 ]; then
            pass "Framebuffer is readable and writable"
        else
            fail "Cannot access framebuffer (run: sudo chmod 666 /dev/fb0)"
        fi

        # Get framebuffer info
        if [ -f /sys/class/graphics/fb0/virtual_size ]; then
            SIZE=$(cat /sys/class/graphics/fb0/virtual_size)
            info "Framebuffer size: $SIZE"
        fi
    else
        fail "Framebuffer device not found (/dev/fb0)"
        info "Run: ./detect_display.sh for help"
    fi

    # Check pygame
    if python3 -c "import pygame" 2>/dev/null; then
        pass "pygame library installed"
    else
        fail "pygame not installed (run: pip install pygame)"
    fi

    echo ""
}

# Test 4: Audio (HiFiBerry)
test_audio() {
    echo "[Test 4/7] Audio (HiFiBerry DAC)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check for sound cards
    if command -v aplay &> /dev/null; then
        CARDS=$(aplay -l 2>/dev/null | grep "^card" | wc -l)
        if [ "$CARDS" -gt 0 ]; then
            pass "Sound card(s) detected (count: $CARDS)"

            # Check for HiFiBerry specifically
            if aplay -l 2>/dev/null | grep -i hifiberry &> /dev/null; then
                pass "HiFiBerry DAC found"
                info "$(aplay -l | grep -i hifiberry | head -1)"
            else
                fail "HiFiBerry not found in audio devices"
                info "Run: ./configure_hifiberry.sh for setup"
            fi
        else
            fail "No sound cards detected"
        fi
    else
        skip "aplay command not available"
    fi

    # Check ALSA configuration
    if [ -f /etc/asound.conf ]; then
        pass "ALSA configuration exists"
    else
        skip "No ALSA configuration (/etc/asound.conf)"
    fi

    echo ""
}

# Test 5: Rotary Encoder Pins
test_rotary() {
    echo "[Test 5/7] Rotary Encoder"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    ROTARY_CLK=17
    ROTARY_DT=27
    ROTARY_SW=22

    info "Expected GPIO pins: CLK=17, DT=27, SW=22"

    # Test GPIO access with Python
    TEST_RESULT=$(python3 -c "
try:
    from gpiozero import Button, RotaryEncoder
    import sys

    # Test rotary encoder pins
    try:
        encoder = RotaryEncoder($ROTARY_CLK, $ROTARY_DT, max_steps=0)
        button = Button($ROTARY_SW)
        encoder.close()
        button.close()
        print('GPIO_OK')
    except Exception as e:
        print(f'GPIO_ERROR: {e}')
        sys.exit(1)
except ImportError as e:
    print(f'IMPORT_ERROR: {e}')
    sys.exit(1)
" 2>&1)

    if echo "$TEST_RESULT" | grep -q "GPIO_OK"; then
        pass "Rotary encoder GPIO pins accessible"
        info "Connect rotary encoder and test manually"
    elif echo "$TEST_RESULT" | grep -q "IMPORT_ERROR"; then
        skip "GPIO libraries not available (mock mode)"
    else
        fail "Cannot access rotary encoder pins"
        info "$TEST_RESULT"
    fi

    echo ""
}

# Test 6: Camera Trigger Pin
test_camera_trigger() {
    echo "[Test 6/7] Camera Trigger"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    CAMERA_PIN=23

    info "Expected GPIO pin: 23"

    # Test camera trigger
    TEST_RESULT=$(python3 -c "
try:
    from gpiozero import OutputDevice
    import time

    trigger = OutputDevice($CAMERA_PIN, initial_value=False)
    trigger.on()
    time.sleep(0.1)
    trigger.off()
    trigger.close()
    print('TRIGGER_OK')
except Exception as e:
    print(f'ERROR: {e}')
" 2>&1)

    if echo "$TEST_RESULT" | grep -q "TRIGGER_OK"; then
        pass "Camera trigger GPIO accessible (100ms pulse sent)"
        info "Check if camera received trigger signal"
    elif echo "$TEST_RESULT" | grep -q "ImportError"; then
        skip "GPIO not available (mock mode)"
    else
        fail "Cannot access camera trigger pin"
        info "$TEST_RESULT"
    fi

    echo ""
}

# Test 7: SamplePi Application
test_samplepi() {
    echo "[Test 7/7] SamplePi Application"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check project directory
    if [ -d "$HOME/SamplePi" ]; then
        pass "SamplePi directory exists"
        PROJECT_DIR="$HOME/SamplePi"
    elif [ -d "$(pwd)/samplepi" ]; then
        pass "SamplePi directory found (current dir)"
        PROJECT_DIR="$(pwd)"
    else
        fail "SamplePi directory not found"
        echo ""
        return
    fi

    # Check virtual environment
    if [ -d "$PROJECT_DIR/.venv" ]; then
        pass "Virtual environment exists"
    else
        fail "Virtual environment not found"
        info "Run: python3 -m venv $PROJECT_DIR/.venv"
    fi

    # Check media directories
    if [ -d "$HOME/media/test_wavs" ] && [ -d "$HOME/media/samples" ]; then
        pass "Media directories exist"

        WAV_COUNT=$(ls -1 "$HOME/media/test_wavs/"*.wav 2>/dev/null | wc -l)
        SAMPLE_COUNT=$(ls -1 "$HOME/media/samples/"*.wav 2>/dev/null | wc -l)
        info "Test WAVs: $WAV_COUNT files"
        info "Samples: $SAMPLE_COUNT files"
    else
        fail "Media directories not found"
        info "Expected: $HOME/media/test_wavs/ and $HOME/media/samples/"
    fi

    # Check systemd service
    if systemctl list-unit-files | grep -q "samplepi.service"; then
        pass "Systemd service installed"

        if systemctl is-enabled samplepi.service &>/dev/null; then
            pass "Service is enabled (auto-start on boot)"
        else
            skip "Service not enabled"
        fi
    else
        skip "Systemd service not installed"
    fi

    echo ""
}

# Run all tests
test_system
test_gpio
test_display
test_audio
test_rotary
test_camera_trigger
test_samplepi

# Summary
echo "========================================"
echo "Test Summary"
echo "========================================"
echo -e "Passed:  ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed:  ${RED}$TESTS_FAILED${NC}"
echo -e "Skipped: ${YELLOW}$TESTS_SKIPPED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC} Hardware is ready."
    echo ""
    echo "To start SamplePi:"
    echo "  sudo systemctl start samplepi"
    echo ""
    echo "To view logs:"
    echo "  sudo journalctl -u samplepi -f"
else
    echo -e "${RED}Some tests failed.${NC} Please fix issues above."
    echo ""
    echo "Common fixes:"
    echo "  Display: ./detect_display.sh"
    echo "  Audio:   ./configure_hifiberry.sh"
    echo "  Setup:   ./pi_setup.sh"
fi

echo ""
exit $TESTS_FAILED
