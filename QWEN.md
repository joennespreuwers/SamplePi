# SamplePi - Raspberry Pi Audio Playback System

## Project Overview

SamplePi is a Raspberry Pi-based audio playback system with camera trigger synchronization. It provides a menu-driven interface for selecting and playing WAV audio files through a HiFiBerry DAC with optional camera trigger support. The application is designed for scientific/testing workflows where audio playback needs to be synchronized with video recording.

### Key Features
- **Menu-driven UI**: Navigate with rotary encoder or touchscreen
- **Dual file selection**: Choose from test WAV files and sample files
- **Sequential playback**: Auto-advances through selected playlist
- **Visual progress tracking**: Progress bar shows playback status
- **Camera trigger**: GPIO pulse to trigger external camera recording
- **Pause/Resume**: Control playback without stopping recording
- **HiFiBerry DAC**: High-quality audio output
- **Framebuffer rendering**: Runs without X11/desktop environment

### Hardware Requirements
- Raspberry Pi (3, 4, or 5 recommended)
- HiFiBerry DAC+ or DAC2 HD
- 3.5" or 5" touchscreen display (480x320)
- Rotary encoder with push button
- Optional: Camera with GPIO trigger capability
- MicroSD card (16GB+)
- Power supply

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
├── install.sh              # One-command installer
├── DEPLOYMENT.md           # Quick deployment guide
├── RASPBERRY_PI_SETUP.md   # Detailed Pi setup
├── README.md               # Project overview
├── requirements.txt        # Python dependencies
└── create_test_files.py    # Generate test WAV files
```

## Building and Running

### Development Environment (Mac/Linux/Windows)

1. **Clone and setup**:
```bash
cd /path/to/SamplePi
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt
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
   - Enter/Space: Select (short press)
   - L: Long press (Next/Advance)
   - ESC: Quit

### Production Environment (Raspberry Pi)

#### One-Command Install
```bash
curl -fsSL https://raw.githubusercontent.com/joennespreuwers/SamplePi/main/install.sh | bash
```

#### Manual Setup
1. Transfer project to Pi:
```bash
rsync -avz --exclude='.venv' ./ pi@raspberrypi.local:/home/pi/SamplePi/
```

2. SSH into Pi and run setup:
```bash
ssh pi@raspberrypi.local
cd /home/pi/SamplePi
./pi_setup.sh
```

### Service Management
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

## Configuration

Key settings in `samplepi/config/settings.py`:

```python
# Display
DISPLAY_WIDTH = 320
DISPLAY_HEIGHT = 240

# GPIO Pins (BCM numbering)
ROTARY_CLK_PIN = 12  # Rotary encoder clock (PWM0 - safe pin)
ROTARY_DT_PIN = 13   # Rotary encoder data (PWM1 - safe pin, was BUTTON_BOTTOM_PIN)
ROTARY_SW_PIN = 16   # Rotary encoder switch/button (CE2 - safe pin)

# Physical buttons on left side of display (top to bottom)
BUTTON_TOP_PIN = 5      # Top button (Home)
BUTTON_MIDDLE_PIN = 6   # Middle button (Next/Action)
BUTTON_BOTTOM_PIN = 19  # Bottom button (Back) - Changed from 13 to avoid conflict

CAMERA_TRIGGER_PIN = 26  # GPIO output for camera trigger
CAMERA_TRIGGER_DURATION = 0.1  # 100ms pulse duration

# Audio
AUDIO_SAMPLE_RATE = 44100
AUDIO_BUFFER_SIZE = 2048

# Media paths
MEDIA_ROOT = os.path.join(PROJECT_ROOT, "test_media")  # For development
# MEDIA_ROOT = "/home/pi/media"  # Uncomment for production on Pi
TEST_WAVS_DIR = os.path.join(MEDIA_ROOT, "test_wavs")
SAMPLES_DIR = os.path.join(MEDIA_ROOT, "samples")
```

## GPIO Wiring

**Rotary Encoder**:
- CLK → GPIO 12
- DT → GPIO 13
- SW → GPIO 16
- GND → Ground
- + → 3.3V

**Physical Buttons** (on left side of display):
- Top Button → GPIO 5 (Home)
- Middle Button → GPIO 6 (Next/Action)
- Bottom Button → GPIO 19 (Back)

**Camera Trigger**:
- GPIO 26 → Camera trigger input (100ms pulse)

**HiFiBerry DAC+**:
- Mounts directly on GPIO header (uses I2S pins)

## User Flow

1. **Start Screen** → Press "Start" to begin new session
2. **Select Test WAVs** → Check files to include, press "Next"
3. **Select Samples** → Check additional files, press "Next"
4. **Recording Toggle** → Enable/disable video recording trigger
5. **Confirm** → Review selections, press "START"
6. **Playback** → Audio plays sequentially with progress indicator
7. **Complete** → Option to play again or return home

## Development Conventions

### Dependencies
- `pygame` >= 2.0.0: For audio playback and UI rendering
- `RPi.GPIO` >= 0.7.0: For GPIO control on Raspberry Pi
- `gpiozero` >= 1.6.0: For simplified GPIO handling

### Code Structure
- **Modular Design**: Separate modules for audio, GPIO, UI, state management
- **Hardware Abstraction**: Mock modes for development without hardware
- **State Management**: Clear separation between UI screens and application state
- **Configuration**: Centralized settings file for easy customization

### Testing
- Development mode with keyboard controls for testing on non-Pi systems
- Mock GPIO implementations for testing without hardware
- Generated test WAV files for development

### Error Handling
- Graceful degradation when hardware is unavailable
- Proper cleanup of resources on shutdown
- Fallback audio drivers for development environments

## Troubleshooting

**Common issues**:
- No audio: Check HiFiBerry configuration in `/boot/firmware/config.txt`
- No display: Verify framebuffer device `/dev/fb0` exists
- GPIO errors: Ensure user is in `gpio` group

For detailed troubleshooting, see [RASPBERRY_PI_SETUP.md](RASPBERRY_PI_SETUP.md#troubleshooting).

## Next Steps

### Flashing the Rotary Encoder Firmware

The Raspberry Pi Pico running the rotary encoder firmware can be flashed using the Arduino CLI as follows:

1. **Compile the firmware**:
```bash
arduino-cli compile --fqbn rp2040:rp2040:rpipico /path/to/pico_rotary_encoder
```

2. **Upload to the Pico**:
```bash
arduino-cli upload -p /dev/cu.usbmodem1101 --fqbn rp2040:rp2040:rpipico /path/to/pico_rotary_encoder
```

This process converts the firmware to a UF2 file and flashes it to the Pico when it enters BOOTSEL mode. The Pico will then operate as a USB HID device, translating rotary encoder inputs to keyboard events.

### Hardware Connections

To complete the SamplePi system, connect the following hardware components:

#### Raspberry Pi Pico (Rotary Encoder Interface)
- Connect the rotary encoder to the Pico:
  - Rotary CLK → GPIO 2 on Pico
  - Rotary DT → GPIO 3 on Pico
  - Rotary SW → GPIO 4 on Pico
  - VCC and GND connections as required

#### Raspberry Pi 4 Connections
- The Pico connects to the Pi 4 via USB cable (provides both power and data communication)
- HiFiBerry DAC connects directly to the Pi 4 GPIO header
- Touchscreen display connects via SPI/I2C (depending on model)
- Camera trigger connects to GPIO 26 on the Pi 4

#### Camera Connection
- Connect the camera trigger wire to GPIO 26 on the Pi 4
- The camera should be configured to accept GPIO-triggered recording start/stop commands

### System Integration and Testing

Once all hardware is connected:

1. The Raspberry Pi Pico acts as a USB keyboard device, sending keystrokes to the Pi 4
2. Rotary encoder movements are translated to arrow keys (for navigation)
3. Button presses are translated to Enter (for selection) and L key (for long press)
4. The SamplePi application receives these keyboard events as standard input
5. When record_video is enabled, GPIO 26 sends 100ms pulses to trigger camera recording

This USB HID approach allows the rotary encoder to function as a generic input device without requiring special drivers, making the system more robust and portable.