# Raspberry Pi Production Setup

This guide covers deploying the SamplePi application to a Raspberry Pi with HiFiBerry DAC+ for high-quality audio output.

## Hardware Requirements

- Raspberry Pi (3, 4, or 5 recommended)
- HiFiBerry DAC+ or DAC2 HD
- 3.5" or 5" touchscreen display (480x320 resolution)
- Rotary encoder with push button
- MicroSD card (16GB+ recommended)
- Power supply
- Optional: Camera module with GPIO trigger capability

## Initial Raspberry Pi Setup

### 1. Install Raspberry Pi OS Lite

```bash
# Flash Raspberry Pi OS Lite (64-bit) to SD card
# Use Raspberry Pi Imager: https://www.raspberrypi.com/software/

# Enable SSH during imaging or create empty 'ssh' file in boot partition
```

### 2. First Boot Configuration

```bash
# SSH into your Pi
ssh pi@raspberrypi.local

# Run raspi-config
sudo raspi-config

# Configure:
# - Enable SPI (Interface Options -> SPI)
# - Enable I2C if using I2C display (Interface Options -> I2C)
# - Set locale and timezone (Localisation Options)
# - Expand filesystem (Advanced Options -> Expand Filesystem)
```

## HiFiBerry DAC+ Configuration

### 1. Edit Boot Config

```bash
sudo nano /boot/firmware/config.txt
```

Add or modify these lines:

```ini
# Disable onboard audio
dtparam=audio=off

# Enable HiFiBerry DAC+
dtoverlay=hifiberry-dacplus

# If using HiFiBerry DAC2 HD, use this instead:
# dtoverlay=hifiberry-dacplushd
```

### 2. Configure ALSA

```bash
# Create or edit ALSA config
sudo nano /etc/asound.conf
```

Add:

```
pcm.!default {
  type hw
  card 0
}

ctl.!default {
  type hw
  card 0
}
```

### 3. Test Audio Output

```bash
# Reboot to apply changes
sudo reboot

# After reboot, check sound cards
aplay -l

# You should see something like:
# card 0: sndrpihifiberry [snd_rpi_hifiberry_dacplus], device 0: HiFiBerry DAC+ HiFi pcm512x-hifi-0 [HiFiBerry DAC+ HiFi pcm512x-hifi-0]

# Test with a WAV file
aplay /usr/share/sounds/alsa/Front_Center.wav
```

## Framebuffer Display Setup

### 1. Configure Display (for standard GPIO displays)

```bash
sudo nano /boot/firmware/config.txt
```

Add display configuration (example for Waveshare 3.5" display):

```ini
# Display settings
hdmi_force_hotplug=1
hdmi_cvt=480 320 60 1 0 0 0
hdmi_group=2
hdmi_mode=87

# Or for SPI display, use appropriate dtoverlay
# Example for Waveshare 3.5" (A)
# dtoverlay=waveshare35a
```

### 2. Disable Console Blanking

```bash
sudo nano /boot/firmware/cmdline.txt
```

Add to the end of the line:

```
consoleblank=0
```

### 3. Install Framebuffer Tools

```bash
sudo apt-get install fbi
```

## SamplePi Installation

### 1. Transfer Project Files

From your Mac, transfer the project to Pi:

```bash
# On your Mac, from the project directory
rsync -avz --exclude='.venv' --exclude='__pycache__' \
  /Users/joenne/Documents/dev/SamplePi/ \
  pi@raspberrypi.local:/home/pi/SamplePi/
```

### 2. Run Setup Script

```bash
# SSH into Pi
ssh pi@raspberrypi.local

# Navigate to project
cd /home/pi/SamplePi

# Run setup script
./pi_setup.sh
```

### 3. Configure Production Settings

Edit the settings file to use production paths:

```bash
nano samplepi/config/settings.py
```

Update:

```python
# Change from:
MEDIA_ROOT = os.path.join(PROJECT_ROOT, "test_media")  # For development

# To:
# MEDIA_ROOT = os.path.join(PROJECT_ROOT, "test_media")  # For development
MEDIA_ROOT = "/home/pi/media"  # Uncomment for production on Pi
```

### 4. Copy Media Files

```bash
# From your Mac:
rsync -avz test_media/test_wavs/ pi@raspberrypi.local:/home/pi/media/test_wavs/
rsync -avz test_media/samples/ pi@raspberrypi.local:/home/pi/media/samples/
```

## GPIO Wiring

### Rotary Encoder

- CLK (Clock) -> GPIO 17
- DT (Data) -> GPIO 27
- SW (Switch) -> GPIO 22
- GND -> Ground
- + -> 3.3V

### Camera Trigger

- GPIO 23 -> Camera trigger input
- Use optocoupler for isolation if needed

### Touchscreen Buttons

Configure based on your touchscreen's GPIO pins or use I2C communication.

## Service Management

### Start SamplePi

```bash
# Start the service
sudo systemctl start samplepi

# Check status
sudo systemctl status samplepi

# View live logs
sudo journalctl -u samplepi -f

# Stop the service
sudo systemctl stop samplepi

# Restart the service
sudo systemctl restart samplepi
```

### Auto-start on Boot

The service is already enabled if you ran the setup script. To manually enable/disable:

```bash
# Enable auto-start
sudo systemctl enable samplepi

# Disable auto-start
sudo systemctl disable samplepi
```

## Troubleshooting

### No Audio Output

```bash
# Check audio devices
aplay -l

# Check HiFiBerry is recognized
dmesg | grep -i hifiberry

# Test pygame mixer directly
python3 -c "import pygame; pygame.mixer.init(); print('Mixer OK')"
```

### Display Not Working

```bash
# Check framebuffer devices
ls -l /dev/fb*

# Test framebuffer
sudo fbi -T 1 -d /dev/fb0 /path/to/image.png

# Check pygame video driver
echo $SDL_VIDEODRIVER
```

### GPIO Not Working

```bash
# Test GPIO access
python3 -c "from gpiozero import LED; led = LED(17); led.on(); print('GPIO OK')"

# Check permissions
groups pi  # Should include 'gpio' group
```

### Service Not Starting

```bash
# Check detailed logs
sudo journalctl -u samplepi -n 100 --no-pager

# Run manually to see errors
cd /home/pi/SamplePi
source .venv/bin/activate
python3 -m samplepi.main
```

## Performance Optimization

### Disable Unnecessary Services

```bash
# Disable Bluetooth if not needed
sudo systemctl disable bluetooth

# Disable WiFi if using Ethernet
sudo systemctl disable wpa_supplicant
```

### Overclock (Optional)

Edit `/boot/firmware/config.txt`:

```ini
# For Pi 4
over_voltage=2
arm_freq=1750
```

## Security Considerations

```bash
# Change default password
passwd

# Update SSH keys
ssh-keygen -t ed25519

# Keep system updated
sudo apt-get update && sudo apt-get upgrade -y
```

## Backup

```bash
# From your Mac, backup the entire SD card periodically
# Or backup just the media directory:
rsync -avz pi@raspberrypi.local:/home/pi/media/ ./backup/media/
```
