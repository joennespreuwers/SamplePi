# Hardware Configuration & Testing Tools

Three helper scripts to configure and test your SamplePi hardware on Raspberry Pi.

## Quick Overview

| Script | Purpose | When to Use |
|--------|---------|-------------|
| [detect_display.sh](detect_display.sh) | Detect and configure display | Display not working or showing black screen |
| [configure_hifiberry.sh](configure_hifiberry.sh) | Auto-configure HiFiBerry DAC | No audio output or setting up for first time |
| [test_hardware.sh](test_hardware.sh) | Test all hardware components | Verify everything works before/after deployment |

---

## 1. Display Detection & Configuration

**[detect_display.sh](detect_display.sh)** - Identifies your display and suggests the correct configuration.

### Usage:
```bash
./detect_display.sh
```

### What it does:
- ✓ Scans I2C and SPI buses for displays
- ✓ Lists available display overlays for your Pi
- ✓ Shows current display configuration
- ✓ Suggests configuration for XPT2046 touchscreen
- ✓ Provides test commands

### Output includes:
- Display hardware detection results
- Available `dtoverlay` options for your display
- Configuration snippets to add to `/boot/firmware/config.txt`
- Testing commands to verify display works

### Common display overlays:
```bash
# Waveshare 3.2" displays
dtoverlay=waveshare32b

# Generic SPI with XPT2046
dtoverlay=piscreen

# HDMI with custom timing
hdmi_cvt=480 320 60 1 0 0 0
hdmi_group=2
hdmi_mode=87
```

---

## 2. HiFiBerry DAC Configuration

**[configure_hifiberry.sh](configure_hifiberry.sh)** - Interactive HiFiBerry DAC setup wizard.

### Usage:
```bash
./configure_hifiberry.sh
```

### What it does:
- ✓ Detects HiFiBerry hardware on I2C bus
- ✓ Shows current audio configuration
- ✓ Interactive model selection menu
- ✓ Automatically updates `/boot/firmware/config.txt`
- ✓ Configures ALSA to use HiFiBerry as default
- ✓ Creates backup before making changes
- ✓ Offers to reboot immediately

### Supported models:
1. HiFiBerry DAC+ (most common) - `dtoverlay=hifiberry-dacplus`
2. HiFiBerry DAC2 HD - `dtoverlay=hifiberry-dacplushd`
3. HiFiBerry DAC+ Pro - `dtoverlay=hifiberry-dacplusadcpro`
4. HiFiBerry DAC Zero - `dtoverlay=hifiberry-dac`

### After reboot, verify:
```bash
# Check audio devices
aplay -l

# Should show:
# card 0: sndrpihifiberry [snd_rpi_hifiberry_dacplus]

# Test audio
speaker-test -c 2
```

---

## 3. Hardware Testing Suite

**[test_hardware.sh](test_hardware.sh)** - Comprehensive hardware verification.

### Usage:
```bash
./test_hardware.sh
```

### What it tests:

#### Test 1: System Information
- Raspberry Pi model detection
- Kernel and Python versions

#### Test 2: GPIO Access
- User permissions (gpio group)
- gpiozero library
- RPi.GPIO library

#### Test 3: Display
- Framebuffer device (`/dev/fb0`)
- Framebuffer permissions
- Display resolution
- pygame library

#### Test 4: Audio (HiFiBerry)
- Sound card detection
- HiFiBerry DAC presence
- ALSA configuration

#### Test 5: Rotary Encoder
- GPIO pins 17, 27, 22 accessible
- Button and encoder functionality

#### Test 6: Camera Trigger
- GPIO pin 23 accessible
- Sends test pulse (100ms)

#### Test 7: SamplePi Application
- Project directory structure
- Virtual environment
- Media files present
- Systemd service installed

### Output format:
```
✓ PASS: Test passed successfully
✗ FAIL: Test failed (with fix suggestion)
⊘ SKIP: Test skipped (not applicable)
```

### Exit codes:
- `0` - All tests passed
- `>0` - Number of failed tests

---

## Typical Setup Workflow

### First Time Setup:

1. **Transfer project to Pi**
   ```bash
   rsync -avz --exclude='.venv' ./ username@raspberrypi.local:~/SamplePi/
   ```

2. **Run main setup**
   ```bash
   ssh username@raspberrypi.local
   cd ~/SamplePi
   ./pi_setup.sh
   ```

3. **Configure HiFiBerry**
   ```bash
   ./configure_hifiberry.sh
   # Select your model, reboot when prompted
   ```

4. **Configure Display**
   ```bash
   ./detect_display.sh
   # Note the suggested overlay
   sudo nano /boot/firmware/config.txt
   # Add suggested overlay, save, reboot
   ```

5. **Test Everything**
   ```bash
   ./test_hardware.sh
   ```

6. **Start SamplePi**
   ```bash
   sudo systemctl start samplepi
   sudo journalctl -u samplepi -f
   ```

---

## Troubleshooting Guide

### No Display / Black Screen

**Run:**
```bash
./detect_display.sh
```

**Common fixes:**
- Ensure correct `dtoverlay` in `/boot/firmware/config.txt`
- Check framebuffer exists: `ls -l /dev/fb0`
- Test with: `sudo fbi -T 1 -d /dev/fb0 image.png`
- Verify SDL environment in systemd service

### No Audio Output

**Run:**
```bash
./configure_hifiberry.sh
```

**Common fixes:**
- Verify HiFiBerry detected: `aplay -l`
- Check boot config has HiFiBerry overlay
- Ensure onboard audio disabled: `dtparam=audio=off`
- Test with: `speaker-test -c 2`

### GPIO Not Working

**Run:**
```bash
./test_hardware.sh
```

**Common fixes:**
- Add user to gpio group: `sudo usermod -a -G gpio $USER`
- Install libraries: `pip install gpiozero RPi.GPIO`
- Check wiring matches pin numbers (BCM mode)
- Verify no conflicting overlays in config.txt

### Service Won't Start

**Run:**
```bash
sudo journalctl -u samplepi -n 50 --no-pager
./test_hardware.sh
```

**Common fixes:**
- Check paths in service file match installation
- Verify virtual environment has all packages
- Ensure media directories exist with WAV files
- Check display/audio configuration is correct

---

## Testing on Mac (Development)

All scripts detect when running on non-Pi hardware:

- **Display detection**: Shows warning, continues with available tests
- **HiFiBerry config**: Prompts for confirmation before proceeding
- **Hardware tests**: Runs in "mock mode", skips GPIO tests

SamplePi app automatically uses mock GPIO and standard pygame window on Mac.

---

## Files Modified by These Scripts

### display detection (detect_display.sh)
- **Reads only** - No modifications

### HiFiBerry configuration (configure_hifiberry.sh)
- `/boot/firmware/config.txt` (or `/boot/config.txt`)
  - Creates backup: `config.txt.backup`
  - Modifies: `dtparam=audio=off`
  - Adds: `dtoverlay=hifiberry-*`
- `/etc/asound.conf`
  - Sets HiFiBerry as default audio device

### Hardware testing (test_hardware.sh)
- **Reads only** - No modifications
- May send GPIO test pulse on pin 23

---

## Integration with Main Setup

These tools complement [pi_setup.sh](pi_setup.sh):

```bash
# Main setup installs software and creates directories
./pi_setup.sh

# Hardware-specific configuration
./configure_hifiberry.sh    # Audio
./detect_display.sh         # Display (manual config needed)

# Verification
./test_hardware.sh

# Deploy
sudo systemctl start samplepi
```

---

## Additional Resources

- [RASPBERRY_PI_SETUP.md](RASPBERRY_PI_SETUP.md) - Detailed setup guide
- [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment workflow
- [README.md](README.md) - Project overview

## Support

If hardware tests pass but SamplePi doesn't work:
1. Check service logs: `sudo journalctl -u samplepi -f`
2. Run manually: `cd ~/SamplePi && source .venv/bin/activate && python3 -m samplepi.main`
3. Verify settings in `samplepi/config/settings.py`
