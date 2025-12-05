# SamplePi

Raspberry Pi audio playback system with camera trigger synchronization. A menu-driven interface for selecting and playing WAV audio files through a HiFiBerry DAC with optional camera trigger support.

## Features

- **Menu-driven UI**: Navigate with rotary encoder or touchscreen
- **Dual file selection**: Choose from test WAV files and sample files
- **Sequential playback**: Auto-advances through selected playlist
- **Visual progress tracking**: Progress bar shows playback status
- **Camera trigger**: GPIO pulse to trigger external camera recording
- **Pause/Resume**: Control playback without stopping recording
- **HiFiBerry DAC**: High-quality audio output
- **Framebuffer rendering**: Runs without X11/desktop environment

## Hardware Requirements

- Raspberry Pi (3, 4, or 5 recommended)
- HiFiBerry DAC+ or DAC2 HD
- 3.5" or 5" touchscreen display (480x320)
- Rotary encoder with push button
- Optional: Camera with GPIO trigger capability
- MicroSD card (16GB+)
- Power supply

## Quick Start

### One-Command Install (Raspberry Pi)

```bash
curl -fsSL https://raw.githubusercontent.com/joennespreuwers/SamplePi/main/install.sh | bash
```

This will:
- Install all system dependencies
- Clone the repository to `~/SamplePi`
- Set up Python virtual environment
- Configure HiFiBerry audio
- Install and enable systemd service
- Set up desktop autostart (if desktop environment detected)

After installation, reboot and SamplePi will start automatically!

### Development (Mac/Linux/Windows)

1. **Clone and setup**:
```bash
cd /path/to/SamplePi
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install pygame
```

2. **Generate test files**:
```bash
python3 create_test_files.py
```

3. **Run application**:
```bash
python3 -m samplepi.main
```

4. **Keyboard controls**:
   - Arrow keys: Navigate menus
   - Enter/Space: Select
   - H: Home button
   - B: Back button
   - N: Next/Action button
   - ESC: Quit

### Production (Raspberry Pi)

See [DEPLOYMENT.md](DEPLOYMENT.md) for quick deployment guide, or [RASPBERRY_PI_SETUP.md](RASPBERRY_PI_SETUP.md) for detailed setup instructions.

**Quick deploy**:
```bash
# Transfer project to Pi
rsync -avz --exclude='.venv' ./ pi@raspberrypi.local:/home/pi/SamplePi/

# SSH into Pi and run setup
ssh pi@raspberrypi.local
cd /home/pi/SamplePi
./pi_setup.sh
```

## Project Structure

```
SamplePi/
├── samplepi/
│   ├── main.py              # Application entry point
│   ├── audio/               # Audio playback engine (pygame.mixer)
│   ├── gpio/                # GPIO handlers (rotary, camera, touchscreen)
│   ├── ui/                  # UI screens and components
│   │   └── screens/         # File selection, playback, confirmation
│   ├── state/               # Application state management
│   └── config/              # Configuration settings
├── test_media/              # Development media files
│   ├── test_wavs/          # Test WAV files
│   └── samples/            # Sample audio files
├── samplepi.service      # Systemd service file
├── pi_setup.sh             # Raspberry Pi automated setup
├── DEPLOYMENT.md           # Quick deployment guide
├── RASPBERRY_PI_SETUP.md   # Detailed Pi setup
└── requirements.txt        # Python dependencies
```

## User Flow

1. **Start Screen** → Press "Start" to begin new session
2. **Select Test WAVs** → Check files to include, press "Next"
3. **Select Samples** → Check additional files, press "Next"
4. **Recording Toggle** → Enable/disable video recording trigger
5. **Confirm** → Review selections, press "START"
6. **Playback** → Audio plays sequentially with progress indicator
7. **Complete** → Option to play again or return home

## Configuration

Key settings in `samplepi/config/settings.py`:

```python
# Display
DISPLAY_WIDTH = 480
DISPLAY_HEIGHT = 320

# GPIO Pins (BCM numbering)
ROTARY_CLK_PIN = 17
ROTARY_DT_PIN = 27
ROTARY_SW_PIN = 22
CAMERA_TRIGGER_PIN = 23

# Audio
AUDIO_SAMPLE_RATE = 44100
AUDIO_BUFFER_SIZE = 2048

# Media paths
MEDIA_ROOT = "/home/pi/media"  # Production
# MEDIA_ROOT = os.path.join(PROJECT_ROOT, "test_media")  # Development
```

## GPIO Wiring

**Rotary Encoder**:
- CLK → GPIO 17
- DT → GPIO 27
- SW → GPIO 22
- GND → Ground
- + → 3.3V

**Camera Trigger**:
- GPIO 23 → Camera trigger input (100ms pulse)

**HiFiBerry DAC+**:
- Mounts directly on GPIO header (uses I2S pins)

## Service Management

```bash
# Start service
sudo systemctl start samplepi

# Check status
sudo systemctl status samplepi

# View logs
sudo journalctl -u samplepi -f

# Stop service
sudo systemctl stop samplepi
```

## Troubleshooting

See [RASPBERRY_PI_SETUP.md](RASPBERRY_PI_SETUP.md#troubleshooting) for detailed troubleshooting.

**Common issues**:
- No audio: Check HiFiBerry configuration in `/boot/firmware/config.txt`
- No display: Verify framebuffer device `/dev/fb0` exists
- GPIO errors: Ensure user is in `gpio` group

## Documentation

- [DEPLOYMENT.md](DEPLOYMENT.md) - Quick deployment guide
- [RASPBERRY_PI_SETUP.md](RASPBERRY_PI_SETUP.md) - Detailed Pi setup and configuration
- [CLAUDE.md](CLAUDE.md) - Project documentation for AI assistants
- [design.md](design.md) - Original design specification

## License

Copyright © 2024. All rights reserved.
