# USB Gadget Toggle Implementation - Summary

## Overview
Implemented on-demand USB gadget mode toggle functionality for SamplePi, triggered by long-pressing the top button (GPIO 5). This allows the Pi to appear as a USB mass storage device for easy file transfer, then return to normal operation with another long-press.

## Files Created

### 1. Toggle Scripts (`usb_gadget/`)
- **`toggle_usb_gadget.sh`** - Interactive toggle script with prompts
- **`toggle_gadget_button.sh`** - Non-interactive version for button-triggered use
- **`samplepi-gadget-toggle.service`** - Systemd service placeholder

### 2. UI Screen (`samplepi/ui/screens/`)
- **`usb_gadget_mode_screen.py`** - Display shown when in USB gadget mode
  - Shows "USB TRANSFER MODE" status
  - Displays instructions for file transfer
  - Blinking hint to exit mode

### 3. Documentation
- **`usb_gadget/TOGGLE_README.md`** - Complete user guide for toggle feature

## Files Modified

### 1. `samplepi/config/settings.py`
**Changes:**
- Added `BUTTON_TOP_PIN = 5` configuration
- Added `BUTTON_MIDDLE_PIN = 6` configuration  
- Added `BUTTON_BOTTOM_PIN = 19` configuration
- Added comments for physical button layout

### 2. `samplepi/gpio/touchscreen.py`
**Changes:**
- Complete rewrite to support 3 physical buttons
- Added long-press detection for top button (USB gadget toggle)
- Implemented separate callbacks for each button:
  - `on_top()` - Short press (Home)
  - `on_top_long_press()` - Long press (USB gadget toggle)
  - `on_middle()` - Middle button (Pause/Resume)
  - `on_bottom()` - Bottom button (Back/Stop)
- Added threading timer for long-press detection
- Added cleanup method for GPIO resources

### 3. `samplepi/main.py`
**Changes:**
- Added `is_usb_gadget_mode()` function to detect current mode
- Added USB gadget mode detection at startup
- Conditional callback registration based on mode:
  - Normal mode: All buttons + rotary encoder active
  - Gadget mode: Only top button long-press active
- Added button handler methods:
  - `handle_usb_gadget_toggle()` - Calls toggle script
  - `handle_top_button()` - Home functionality
  - `handle_middle_button()` - Context action
  - `handle_bottom_button()` - Back/Stop
- Added keyboard shortcuts for testing:
  - `T` - Toggle USB gadget
  - `H` - Home
  - `M` - Middle button
  - `B` - Bottom button
- Updated cleanup to include touchscreen

### 4. `samplepi/ui/screens/__init__.py`
**Changes:**
- Added import for `UsbGadgetModeScreen`

### 5. `samplepi/ui/screens/playback_screen.py`
**Changes:**
- Added `handle_top_button()` method (no-op during playback)
- Added `handle_middle_button()` method (pause/resume)
- Added `handle_bottom_button()` method (stop playback)
- Added docstring with button mappings

### 6. `usb_gadget/setup_usb_gadget.sh`
**Changes:**
- Added header explaining on-demand mode
- Added toggle script installation
- Created sudoers entry for passwordless toggle
- Updated completion message with toggle instructions
- Added symlink for easy toggle access

## How It Works

### Toggle Flow
```
Normal Mode (SamplePi running)
       │
       │ Long-press TOP button (1s)
       ▼
Toggle script executes
  - Modifies /boot/config.txt
  - Modifies /boot/cmdline.txt
  - Enables usb-gadget.service
       │
       ▼
System reboots
       │
       ▼
USB Gadget Mode
  - Pi appears as USB drive
  - SamplePi shows gadget screen
  - Pico input ignored
       │
       │ Long-press TOP button (1s)
       ▼
Toggle script executes
  - Reverts config changes
  - Syncs files from gadget storage
  - Disables usb-gadget.service
       │
       ▼
System reboots
       │
       ▼
Normal Mode (SamplePi running)
```

### Button Mappings

#### Normal Mode
| Button | Short Press | Long Press |
|--------|-------------|------------|
| Top (GPIO 5) | Home | Toggle USB gadget |
| Middle (GPIO 6) | Pause/Resume | N/A |
| Bottom (GPIO 19) | Back/Stop | N/A |

#### USB Gadget Mode
| Button | Short Press | Long Press |
|--------|-------------|------------|
| Top (GPIO 5) | No-op | Exit USB gadget |
| Middle (GPIO 6) | No-op | No-op |
| Bottom (GPIO 19) | No-op | No-op |

## Deployment Steps

### On Raspberry Pi 4:

1. **Transfer code to Pi:**
   ```bash
   rsync -avz --exclude='.venv' ./ pi@raspberrypi.local:/home/pi/SamplePi/
   ```

2. **SSH into Pi and run setup:**
   ```bash
   ssh pi@raspberrypi.local
   cd /home/pi/SamplePi
   
   # Run USB gadget setup (one-time)
   chmod +x usb_gadget/setup_usb_gadget.sh
   ./usb_gadget/setup_usb_gadget.sh
   
   # Reboot
   sudo reboot
   ```

3. **Test the toggle:**
   - Start SamplePi: `sudo systemctl start samplepi`
   - Long-press TOP button for 1 second
   - Pi should reboot into USB gadget mode
   - Connect Pi to computer via USB
   - Verify "SamplePi Media Storage" appears
   - Long-press TOP button again to exit

### Manual Toggle (for testing):
```bash
sudo /usr/local/bin/samplepi_toggle_gadget.sh
```

## Testing on Mac (Development)

The code includes mock GPIO mode for testing without hardware:

```bash
# Run locally on Mac
python3 -m samplepi.main

# Keyboard shortcuts for testing:
# T - Toggle USB gadget
# H - Home (top button)
# M - Middle button
# B - Bottom button
# ESC - Quit
```

Note: USB gadget toggle only works on Raspberry Pi (requires GPIO and system config access).

## Technical Considerations

### Safety Features
1. **Config backup** - Original `/boot/config.txt` backed up before modifications
2. **File sync** - Automatic sync when exiting gadget mode prevents data loss
3. **Process checking** - Sync only runs when SamplePi is not active
4. **Logging** - All toggle operations logged to `/var/log/samplepi-gadget-toggle.log`

### Limitations
1. **Reboot required** - USB controller mode change requires system reboot
2. **Pico disabled in gadget mode** - Expected behavior (Pi is USB device, not host)
3. **Single USB function** - Can't use other USB peripherals in gadget mode

### Future Enhancements
1. **Shorter toggle time** - Could reduce long-press duration from 1s to 0.5s
2. **Visual countdown** - Show countdown before reboot during toggle
3. **Confirmation dialog** - Require double-press to prevent accidental toggles
4. **Network toggle** - Add API endpoint to trigger toggle remotely

## Verification Checklist

- [x] Python code compiles without errors
- [x] All imports resolve correctly
- [x] Button callbacks properly registered
- [x] USB gadget mode detection works
- [x] Toggle scripts are executable
- [x] Documentation complete
- [ ] Deploy to Pi and test hardware (requires physical device)

## Related Files

### Core Implementation
- `samplepi/main.py` - Main application with mode detection
- `samplepi/gpio/touchscreen.py` - Button input handling
- `samplepi/ui/screens/usb_gadget_mode_screen.py` - Gadget mode UI

### Toggle Scripts
- `usb_gadget/toggle_gadget_button.sh` - Button-triggered toggle
- `usb_gadget/toggle_usb_gadget.sh` - Interactive toggle
- `usb_gadget/setup_usb_gadget.sh` - Initial setup

### Configuration
- `samplepi/config/settings.py` - GPIO pin definitions
- `samplepi/ui/screens/__init__.py` - Screen imports

### Documentation
- `usb_gadget/TOGGLE_README.md` - User guide
- `usb_gadget/IMPLEMENTATION.md` - Technical details (existing)
- `usb_gadget/USAGE_GUIDE.md` - Usage guide (existing)
