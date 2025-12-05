# Getting Started with SamplePi

Complete walkthrough for deploying SamplePi to your Raspberry Pi from scratch.

---

## 📋 Prerequisites

Before you begin, make sure you have:

- ✅ Raspberry Pi (3, 4, or 5)
- ✅ MicroSD card (16GB+) with Raspberry Pi OS Lite installed
- ✅ HiFiBerry DAC+ mounted on Pi
- ✅ 3.21" display with XPT2046 controller (480x320)
- ✅ Rotary encoder
- ✅ 3 physical buttons on display (left side: top, middle, bottom)
- ✅ Mac/PC for development and deployment
- ✅ Network connection (SSH access to Pi)

---

## 🚀 Step-by-Step Deployment

### Phase 1: Development Setup (On Your Mac)

#### 1.1 Clone or Navigate to Project

```bash
cd /Users/joenne/Documents/dev/SamplePi
```

#### 1.2 Create Python Virtual Environment

```bash
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
```

#### 1.3 Install Dependencies

```bash
pip install pygame
```

#### 1.4 Generate Test Audio Files

```bash
python3 create_test_files.py
```

You should see:
```
Generating test WAV files...
  Created: 440hz_test.wav (A4 note, 2 seconds)
  Created: 880hz_test.wav (A5 note, 2 seconds)
  Created: 220hz_test.wav (A3 note, 2 seconds)

Generating sample files...
  Created: 1khz_sample.wav (1kHz tone, 3 seconds)
  Created: 500hz_sample.wav (500Hz tone, 3 seconds)

All test files created successfully!
```

#### 1.5 Test on Mac (Optional but Recommended)

```bash
python3 -m samplepi.main
```

**Keyboard controls for testing:**
- ↑↓ Arrow keys: Navigate menus
- Enter/Space: Select current item
- **H**: Home button (top button)
- **B**: Back button (middle button)
- **N**: Next button (bottom button)
- ESC: Quit

Navigate through the menus to verify everything works. Press ESC to exit.

---

### Phase 2: Raspberry Pi Preparation

#### 2.1 Flash Raspberry Pi OS

1. Download [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. Flash **Raspberry Pi OS Lite (64-bit)** to your SD card
3. **Enable SSH** during imaging (or create empty `ssh` file in boot partition)
4. Set hostname (e.g., `raspberrypi`)
5. Configure WiFi/Ethernet

#### 2.2 First Boot & Initial Setup

```bash
# SSH into your Pi
ssh pi@raspberrypi.local
# Default password: raspberry

# Change default password (IMPORTANT!)
passwd

# Run initial configuration
sudo raspi-config
```

In `raspi-config`:
- **Interface Options** → Enable **SPI** (for display)
- **Interface Options** → Enable **I2C** (if needed)
- **Localisation Options** → Set timezone
- **Advanced Options** → Expand Filesystem
- Finish and reboot

---

### Phase 3: Transfer Project to Pi

#### 3.1 Transfer Files from Mac

```bash
# From your Mac, in the SamplePi directory
rsync -avz --exclude='.venv' --exclude='__pycache__' \
  /Users/joenne/Documents/dev/SamplePi/ \
  pi@raspberrypi.local:~/SamplePi/
```

Wait for transfer to complete (~30 seconds).

#### 3.2 Transfer Test Media Files

```bash
# Transfer test audio files
rsync -avz test_media/ pi@raspberrypi.local:~/media/
```

---

### Phase 4: Install Software on Pi

#### 4.1 SSH into Pi and Run Setup Script

```bash
# SSH into Pi
ssh pi@raspberrypi.local

# Navigate to project
cd ~/SamplePi

# Make setup script executable (if not already)
chmod +x pi_setup.sh

# Run automated setup
./pi_setup.sh
```

This script will:
- ✓ Update system packages
- ✓ Install dependencies (pygame, GPIO libraries)
- ✓ Create virtual environment
- ✓ Create media directories
- ✓ Install systemd service
- ✓ Enable auto-start on boot

**Wait for completion** (~5-10 minutes depending on internet speed).

---

### Phase 5: Configure HiFiBerry Audio

#### 5.1 Run HiFiBerry Configuration Script

```bash
./configure_hifiberry.sh
```

**Select your HiFiBerry model:**
```
Select your HiFiBerry model:
  1) HiFiBerry DAC+ (most common)
  2) HiFiBerry DAC2 HD
  3) HiFiBerry DAC+ Pro
  4) HiFiBerry DAC Zero
  5) Skip configuration

Enter choice [1-5]:
```

Choose the correct model (usually **1** for DAC+).

#### 5.2 Reboot When Prompted

```
IMPORTANT: You must reboot for changes to take effect!

Reboot now? (y/n)
```

Press **y** to reboot.

#### 5.3 Verify Audio After Reboot

```bash
# SSH back in after reboot
ssh pi@raspberrypi.local

# Check HiFiBerry is detected
aplay -l
```

You should see:
```
card 0: sndrpihifiberry [snd_rpi_hifiberry_dacplus], device 0: HiFiBerry DAC+ HiFi pcm512x-hifi-0
```

**Test audio output:**
```bash
speaker-test -c 2 -t wav
```

Press Ctrl+C to stop. You should hear test tones from both speakers.

---

### Phase 6: Configure Display

#### 6.1 Detect Display Hardware

```bash
cd ~/SamplePi
./detect_display.sh
```

This will scan for your display and suggest configuration.

#### 6.2 Configure Display Overlay

**Find your display type** from the suggestions, then:

```bash
sudo nano /boot/firmware/config.txt
```

**Add the appropriate overlay** (example for Waveshare 3.2"):
```ini
# Disable HDMI
hdmi_blanking=2

# Display overlay (adjust for your specific display)
dtoverlay=waveshare32b
dtparam=speed=20000000
dtparam=rotate=270

# OR for generic HDMI timing:
# hdmi_force_hotplug=1
# hdmi_cvt=480 320 60 1 0 0 0
# hdmi_group=2
# hdmi_mode=87
```

**Disable console blanking:**
```bash
sudo nano /boot/firmware/cmdline.txt
```

Add `consoleblank=0` to the end of the line.

**Save and reboot:**
```bash
sudo reboot
```

#### 6.3 Verify Display After Reboot

```bash
# Check framebuffer exists
ls -l /dev/fb0

# Should show something like:
# crw-rw---- 1 root video 29, 0 Dec 3 12:00 /dev/fb0
```

---

### Phase 7: Configure GPIO Pins

#### 7.1 Update Pin Numbers for Your Hardware

```bash
nano ~/SamplePi/samplepi/config/settings.py
```

**Verify/update GPIO pins:**
```python
# GPIO Pin assignments (BCM numbering)
ROTARY_CLK_PIN = 17  # Rotary encoder clock
ROTARY_DT_PIN = 27   # Rotary encoder data
ROTARY_SW_PIN = 22   # Rotary encoder switch/button

# Physical buttons on left side of display (top to bottom)
BUTTON_TOP_PIN = 5      # Top button (Home) - UPDATE THIS
BUTTON_MIDDLE_PIN = 6   # Middle button (Back) - UPDATE THIS
BUTTON_BOTTOM_PIN = 13  # Bottom button (Next/Action) - UPDATE THIS

CAMERA_TRIGGER_PIN = 23  # GPIO output for camera trigger
```

**Change these numbers** to match your display's actual button GPIO pins.

#### 7.2 Update Media Path for Production

In the same file, change:
```python
# File paths
MEDIA_ROOT = os.path.join(PROJECT_ROOT, "test_media")  # For development
# MEDIA_ROOT = "/home/pi/media"  # Uncomment for production on Pi
```

To:
```python
# File paths
# MEDIA_ROOT = os.path.join(PROJECT_ROOT, "test_media")  # For development
MEDIA_ROOT = os.path.expanduser("~/media")  # For production on Pi
```

Save and exit (Ctrl+X, Y, Enter).

---

### Phase 8: Test Hardware

#### 8.1 Run Hardware Test Suite

```bash
cd ~/SamplePi
./test_hardware.sh
```

This will test:
- ✓ System information
- ✓ GPIO access
- ✓ Display (framebuffer)
- ✓ Audio (HiFiBerry)
- ✓ Rotary encoder pins
- ✓ Camera trigger pin
- ✓ SamplePi installation

**Expected output:**
```
========================================
Test Summary
========================================
Passed:  X
Failed:  0
Skipped: X

All tests passed! Hardware is ready.
```

If any tests fail, follow the suggestions provided.

---

### Phase 9: Start SamplePi

#### 9.1 Start the Service

```bash
sudo systemctl start samplepi
```

#### 9.2 Check Status

```bash
sudo systemctl status samplepi
```

You should see:
```
● samplepi.service - SamplePi Audio Playback System
   Active: active (running) since ...
```

#### 9.3 View Live Logs

```bash
sudo journalctl -u samplepi -f
```

Press Ctrl+C to exit log view.

---

### Phase 10: Test Full Workflow

#### 10.1 Navigate the Interface

Using your **rotary encoder** and **physical buttons**, test the complete workflow:

1. **Start Screen** → Rotate to "Start New Session", press rotary button
2. **Select Test WAVs** → Rotate to select files, press to check/uncheck, press "Next" button (bottom)
3. **Select Samples** → Same as above, press "Next" when done
4. **Recording Toggle** → Rotate to ON/OFF, press to toggle, press "Next"
5. **Confirm Screen** → Verify selections, press "START" button (bottom)
6. **Playback** → Audio should play automatically, progress bar advances
7. **Complete** → Choose "Play Again" or "Return to Home"

#### 10.2 Test All Controls

**During playback:**
- **Top button (Home)**: Returns to start
- **Middle button (Back)**: Pauses/Resumes
- **Bottom button (Next)**: Stops playback
- **Rotary encoder**: Should pause the current track

**If recording is enabled**, you should see:
```
Camera trigger: pulse sent
```
in the logs.

---

## 🎯 Success Criteria

Your SamplePi is fully operational when:

✅ Display shows SamplePi UI (480x320)
✅ Rotary encoder scrolls through menus
✅ Physical buttons respond correctly
✅ Audio plays through HiFiBerry DAC
✅ Files auto-advance sequentially
✅ Progress bar updates in real-time
✅ Camera trigger fires when recording enabled
✅ Service auto-starts on boot

---

## 🔧 Troubleshooting

### Display Shows Nothing

```bash
./detect_display.sh
# Follow suggestions and reboot
```

### No Audio Output

```bash
./configure_hifiberry.sh
# Select correct model and reboot
```

### Service Won't Start

```bash
sudo journalctl -u samplepi -n 50 --no-pager
# Check error messages
./test_hardware.sh
# Fix any failing tests
```

### GPIO Buttons Not Working

1. Check GPIO pin numbers in `settings.py`
2. Test with: `gpio readall` (install with `sudo apt-get install wiringpi`)
3. Verify buttons are wired correctly

---

## 📖 Additional Resources

- **[README.md](README.md)** - Project overview
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Quick deployment reference
- **[RASPBERRY_PI_SETUP.md](RASPBERRY_PI_SETUP.md)** - Detailed hardware configuration
- **[HARDWARE_TOOLS.md](HARDWARE_TOOLS.md)** - Hardware testing tool documentation

---

## 🎉 You're Done!

Your SamplePi is now running on your Raspberry Pi!

### Next Steps:

1. **Add your own WAV files** to `~/media/test_wavs/` and `~/media/samples/`
2. **Configure camera trigger** if using video recording
3. **Test thoroughly** with actual recordings
4. **Customize settings** in `samplepi/config/settings.py` as needed

### Service Management Commands:

```bash
# Start
sudo systemctl start samplepi

# Stop
sudo systemctl stop samplepi

# Restart
sudo systemctl restart samplepi

# View logs
sudo journalctl -u samplepi -f

# Disable auto-start
sudo systemctl disable samplepi

# Enable auto-start
sudo systemctl enable samplepi
```

---

## 💡 Pro Tips

1. **Development Workflow**: Test changes on Mac first, then deploy to Pi
2. **Quick Deploy**: Use `rsync` to sync only changed files
3. **Debugging**: Run manually to see errors:
   ```bash
   cd ~/SamplePi
   source .venv/bin/activate
   python3 -m samplepi.main
   ```
4. **Backup**: Regularly backup `~/media/` and `~/SamplePi/samplepi/config/settings.py`

---

**Need Help?** Check the troubleshooting section above or review the detailed documentation in [RASPBERRY_PI_SETUP.md](RASPBERRY_PI_SETUP.md).
