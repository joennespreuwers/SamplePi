
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Python-based Raspberry Pi media player application designed for scientific/testing workflows. The system plays WAV files through a HiFiBerry DAC Pro XLR and triggers a camera via GPIO to synchronize audio playback with video recording.

### Hardware Setup
- **Platform**: Raspberry Pi
- **Audio**: HiFiBerry DAC Pro XLR
- **Display**: 3.21" touchscreen with XPT2046 touch controller
- **Input**: Rotary encoder (scroll, short press = select, long press = next)
- **Output**: GPIO pin for camera trigger (100ms HIGH pulse to simulate record button)

## Architecture

### Core Components (to be implemented)

1. **Audio Engine**: Handles WAV file playback through HiFiBerry
   - Must support multiple file playback in sequence
   - Pause/resume functionality (should NOT affect recording state)
   - Stop functionality

2. **GPIO Controller**: Manages hardware I/O
   - Rotary encoder input handling (rotation, short press, long press)
   - Camera trigger output (100ms pulse on recording start)
   - Touch screen input integration

3. **Display Manager**: Renders menu system on 3.21" touchscreen
   - Menu-driven interface (similar to 3D printer UI like Ender)
   - Context-aware button layout (different buttons for playing vs idle states)

4. **State Machine**: Orchestrates application flow
   - Menu navigation states
   - Playback states (idle, playing, paused)
   - Recording state tracking

### User Flow

**Setup Sequence**:
1. Start screen
2. Select test WAV file(s) - multiple selection supported
3. Select sample file(s) - multiple selection supported
4. Toggle video recording option
5. Press to start playback/recording

**Playback Controls** (3 touchscreen buttons during playback):
- Pause/Resume (does NOT affect camera recording state)
- Stop test
- Reset/Reboot

**Navigation Controls** (3 touchscreen buttons when idle):
- Home
- Next (context-sensitive: advances to next menu screen, or next page during file selection)
- Go back

**Post-playback Options**:
- Play again
- Return to home

### Input Handling

- **Rotary Encoder**:
  - Rotation: Scroll through vertical menu
  - Press: Select current item

- **Touchscreen**: Three context-sensitive buttons
  - Left: Home (return to start screen)
  - Middle: Next (advances to next menu screen or next page during file selection)
  - Right: Go back (return to previous screen)

## Development Considerations

### System Setup

**Operating System**: Raspbian Lite (bare metal, no desktop environment)

This application runs directly on the framebuffer without X11/desktop environment for:
- Faster boot times and lower resource usage
- Dedicated appliance-like experience
- Maximum CPU/memory available for audio processing

### Python Libraries (suggested)
- **Audio**: `pygame.mixer` for WAV playback (lightweight, direct ALSA support)
- **GPIO**: `RPi.GPIO` or `gpiozero` for hardware control
- **Display**: `pygame` running on framebuffer (`/dev/fb0`)
- **Rotary Encoder**: `gpiozero.RotaryEncoder` or custom interrupt-based handler
- **Touchscreen**: Framebuffer touchscreen driver for XPT2046

### Framebuffer Setup

To run pygame on bare metal Raspbian Lite:

1. **Environment variables** (set in systemd service or shell):
   ```bash
   SDL_VIDEODRIVER=fbcon
   SDL_FBDEV=/dev/fb0
   SDL_NOMOUSE=1
   ```

2. **Required packages**:
   ```bash
   sudo apt-get install python3-pygame python3-rpi.gpio python3-gpiozero
   sudo apt-get install fbset fbi  # framebuffer utilities
   ```

3. **Display driver**: Install drivers for 3.21" XPT2046 display to enable framebuffer support
   - Configure in `/boot/config.txt` with appropriate dtoverlay
   - Touchscreen input typically available at `/dev/input/eventX`

4. **Auto-start**: Use systemd service to launch application on boot

### Critical Synchronization Requirements

1. **Recording Independence**: Pause/resume audio playback MUST NOT affect the camera recording state once started
2. **GPIO Timing**: Camera trigger requires precisely 100ms HIGH pulse
3. **Multiple File Playback**: Support sequential playback of multiple selected files
4. **State Persistence**: Track which files have been played in current session

### File Organization (recommended structure)

```
samplepi/
├── audio/          # Audio playback engine
├── gpio/           # Hardware I/O controllers
├── ui/             # Display and menu system
├── state/          # State machine and session management
├── config/         # Configuration files (audio paths, GPIO pins, etc.)
└── main.py         # Application entry point
```

## Testing Strategy

Due to hardware dependencies, consider:
- Mock GPIO and audio interfaces for development without hardware
- Separate business logic from hardware I/O for unit testing
- Integration tests on actual Raspberry Pi hardware
- Test rotary encoder debouncing and long-press detection timing
- Verify GPIO pulse timing with oscilloscope or logic analyzer
