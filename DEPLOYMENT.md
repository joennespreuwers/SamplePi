# SamplePi Deployment Guide

Quick reference guide for deploying SamplePi to Raspberry Pi.

## Quick Start

### 1. Prepare Raspberry Pi

```bash
# Flash Raspberry Pi OS Lite to SD card
# Enable SSH during setup

# Boot Pi and configure
ssh pi@raspberrypi.local
sudo raspi-config
# Enable: SPI, I2C (if needed)
# Set: Locale, Timezone
# Expand filesystem
```

### 2. Transfer Project

```bash
# From your Mac
cd /Users/joenne/Documents/dev/SamplePi
rsync -avz --exclude='.venv' --exclude='__pycache__' \
  ./ pi@raspberrypi.local:/home/pi/SamplePi/
```

### 3. Run Setup

```bash
# On the Pi
ssh pi@raspberrypi.local
cd /home/pi/SamplePi
./pi_setup.sh
```

### 4. Configure HiFiBerry DAC

```bash
# Edit boot config
sudo nano /boot/firmware/config.txt

# Add:
dtparam=audio=off
dtoverlay=hifiberry-dacplus

# Save and reboot
sudo reboot
```

### 5. Update Settings for Production

```bash
# Edit settings
nano samplepi/config/settings.py

# Change MEDIA_ROOT:
# From: MEDIA_ROOT = os.path.join(PROJECT_ROOT, "test_media")
# To:   MEDIA_ROOT = "/home/pi/media"
```

### 6. Copy Media Files

```bash
# From your Mac
rsync -avz test_media/test_wavs/ pi@raspberrypi.local:/home/pi/media/test_wavs/
rsync -avz test_media/samples/ pi@raspberrypi.local:/home/pi/media/samples/
```

### 7. Start Service

```bash
# On the Pi
sudo systemctl start samplepi
sudo systemctl status samplepi
```

## Development Workflow

### Testing on Mac

```bash
# Activate virtual environment
cd /Users/joenne/Documents/dev/SamplePi
source .venv/bin/activate  # or . .venv/bin/activate

# Run application
python3 -m samplepi.main

# Keyboard controls:
# - Arrow keys: Navigate menus
# - Enter/Space: Select
# - H: Home button
# - B: Back button
# - N: Next/Action button
# - ESC: Quit (development only)
```

### Deploying Changes

```bash
# After making changes on Mac, sync to Pi:
rsync -avz --exclude='.venv' --exclude='__pycache__' \
  /Users/joenne/Documents/dev/SamplePi/ \
  pi@raspberrypi.local:/home/pi/SamplePi/

# Restart service on Pi:
ssh pi@raspberrypi.local 'sudo systemctl restart samplepi'
```

### Viewing Logs

```bash
# SSH into Pi and view live logs
ssh pi@raspberrypi.local
sudo journalctl -u samplepi -f

# View last 50 lines
sudo journalctl -u samplepi -n 50
```

## File Structure

```
SamplePi/
├── samplepi/               # Main application package
│   ├── main.py               # Application entry point
│   ├── audio/                # Audio playback engine
│   ├── gpio/                 # GPIO handlers (rotary, camera, touchscreen)
│   ├── ui/                   # UI screens and components
│   │   └── screens/          # Individual screen implementations
│   ├── state/                # Application state management
│   └── config/               # Configuration settings
├── test_media/               # Development media (Mac only)
│   ├── test_wavs/           # Test WAV files
│   └── samples/             # Sample audio files
├── samplepi.service       # Systemd service file
├── pi_setup.sh              # Raspberry Pi setup script
├── RASPBERRY_PI_SETUP.md    # Detailed Pi setup guide
├── DEPLOYMENT.md            # This file
├── README.md                # Project overview
├── requirements.txt         # Python dependencies
└── create_test_files.py     # Generate test WAV files

Production (on Pi):
/home/pi/SamplePi/         # Application
/home/pi/media/              # Production media
├── test_wavs/              # Test WAV files
└── samples/                # Sample audio files
```

## Common Commands

### Service Management

```bash
# Start
sudo systemctl start samplepi

# Stop
sudo systemctl stop samplepi

# Restart
sudo systemctl restart samplepi

# Status
sudo systemctl status samplepi

# Enable auto-start
sudo systemctl enable samplepi

# Disable auto-start
sudo systemctl disable samplepi
```

### Manual Testing

```bash
# Run manually (useful for debugging)
cd /home/pi/SamplePi
source .venv/bin/activate
python3 -m samplepi.main
```

### Audio Testing

```bash
# List audio devices
aplay -l

# Test audio output
aplay /usr/share/sounds/alsa/Front_Center.wav

# Check HiFiBerry
dmesg | grep -i hifiberry
```

## Configuration Files

### Settings (samplepi/config/settings.py)

Key settings to adjust:

```python
# Display
DISPLAY_WIDTH = 480
DISPLAY_HEIGHT = 320
FPS = 30

# GPIO Pins (BCM numbering)
ROTARY_CLK_PIN = 17
ROTARY_DT_PIN = 27
ROTARY_SW_PIN = 22
CAMERA_TRIGGER_PIN = 23

# Audio
AUDIO_SAMPLE_RATE = 44100
AUDIO_BUFFER_SIZE = 2048

# Paths
MEDIA_ROOT = "/home/pi/media"  # Production
# MEDIA_ROOT = os.path.join(PROJECT_ROOT, "test_media")  # Development
```

### Service File (samplepi.service)

Located at `/etc/systemd/system/samplepi.service` after installation:

```ini
[Unit]
Description=SamplePi Audio Playback System
After=multi-user.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/SamplePi
Environment="DISPLAY=:0"
Environment="SDL_FBDEV=/dev/fb0"
Environment="SDL_VIDEODRIVER=fbcon"
ExecStart=/home/pi/SamplePi/.venv/bin/python3 -m samplepi.main
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

## Troubleshooting Quick Reference

### No Display

```bash
# Check framebuffer
ls -l /dev/fb*

# Set video driver
export SDL_VIDEODRIVER=fbcon
export SDL_FBDEV=/dev/fb0
```

### No Audio

```bash
# Verify HiFiBerry config in /boot/firmware/config.txt
dtparam=audio=off
dtoverlay=hifiberry-dacplus

# Check sound card
aplay -l
```

### GPIO Errors

```bash
# Check GPIO group membership
groups pi

# Add to gpio group if missing
sudo usermod -a -G gpio pi
```

### Service Won't Start

```bash
# Check logs
sudo journalctl -u samplepi -n 100 --no-pager

# Check file permissions
ls -la /home/pi/SamplePi
```

## Hardware Connections

### Rotary Encoder
- CLK → GPIO 17
- DT → GPIO 27
- SW → GPIO 22
- GND → Ground
- + → 3.3V

### Camera Trigger
- GPIO 23 → Camera trigger (100ms pulse)

### HiFiBerry DAC+
- Mounts directly on Pi GPIO header (pins 1-40)
- Provides I2S audio output

## Support

For detailed setup instructions, see [RASPBERRY_PI_SETUP.md](RASPBERRY_PI_SETUP.md)

For project overview and design, see [README.md](README.md) and [design.md](design.md)
