# USB Gadget Mode - On-Demand Toggle

This feature allows the SamplePi to toggle USB gadget mode on-demand by long-pressing the **TOP button** (GPIO 5).

## Overview

When USB gadget mode is enabled, the Raspberry Pi appears as a USB mass storage device named **"SamplePi Media Storage"** when connected to a computer. This allows easy file transfer of audio samples without requiring network connectivity.

## Quick Start

### Enter USB Gadget Mode
1. From the SamplePi home screen, **long-press the TOP button** (GPIO 5) for 1 second
2. The Pi will reboot automatically
3. Connect the Pi to your computer via USB
4. The Pi appears as "SamplePi Media Storage" drive
5. Copy files to/from the `samples/` and `test_wavs/` directories

### Exit USB Gadget Mode
1. **Long-press the TOP button** again for 1 second
2. The Pi will reboot back to normal mode
3. Pico keyboard input works again
4. SamplePi application runs normally

## Button Mappings

### Normal Mode (Default)
| Button | Action |
|--------|--------|
| **Top (short)** | Home / Go to start screen |
| **Top (long)** | Toggle USB gadget mode |
| **Middle** | Context action (Pause/Resume during playback) |
| **Bottom** | Back / Stop |

### USB Gadget Mode
| Button | Action |
|--------|--------|
| **Top (long)** | Exit USB gadget mode |
| **Top (short)** | No-op |
| **Middle** | No-op |
| **Bottom** | No-op |

## How It Works

### Toggle Mechanism
- Long-press detection is handled by `touchscreen.py`
- 1-second hold triggers the toggle
- Toggle script modifies `/boot/config.txt` and `/boot/cmdline.txt`
- System reboots to apply changes

### File Synchronization
- When entering gadget mode: Files are copied to the virtual storage image
- When exiting gadget mode: New files are synced back to `/home/pi/media/`
- Automatic sync prevents data loss

## Manual Toggle

You can also toggle USB gadget mode manually via SSH:

```bash
sudo /usr/local/bin/samplepi_toggle_gadget.sh
```

Or from the SamplePi directory:
```bash
sudo ./toggle_gadget.sh
```

## Technical Details

### Configuration Files Modified
- `/boot/config.txt` - Adds/removes `dtoverlay=dwc2`
- `/boot/cmdline.txt` - Adds/removes `modules-load=dwc2,g_mass_storage`

### Storage Image
- Location: `/home/pi/samplepi_media_storage.img`
- Size: Dynamically calculated based on media content + 100MB buffer
- Format: FAT32 (compatible with Windows/Mac/Linux)

### Systemd Services
- `usb-gadget.service` - Manages USB gadget functionality
- `samplepi-gadget-sync.service` - Handles automatic file synchronization

## Troubleshooting

### Pi Doesn't Appear as USB Drive
1. Ensure you're using the correct USB port (the power port on Pi 4)
2. Check that the Pi has fully booted
3. Verify the USB cable supports data transfer (not just power)
4. Try running the toggle script manually: `sudo samplepi_toggle_gadget.sh`

### Toggle Button Not Working
1. Check that the button is wired to GPIO 5
2. Verify SamplePi application is running
3. Check logs: `sudo journalctl -u samplepi -f`

### Files Not Syncing
1. Ensure SamplePi is not running during sync
2. Check file permissions: `ls -la /home/pi/media/`
3. Review sync log: `cat /var/log/samplepi-gadget-toggle.log`

### Accidentally Triggered Gadget Mode
- If you long-press the button by mistake, simply long-press again to exit
- Or SSH in and run: `sudo samplepi_toggle_gadget.sh`

## Safety Features

### Process Checking
- Sync operations only run when SamplePi is not actively using media files
- Prevents file corruption during playback

### Config Backup
- Original `/boot/config.txt` is backed up to `/boot/config.txt.backup`
- Can be restored manually if needed

### Safe Eject
- Files are synced before disabling gadget mode
- Ensures data integrity on disconnection

## Integration with Pico

When USB gadget mode is active:
- The Pico keyboard input is **ignored** by the application
- This is expected behavior - the Pi's USB controller is in device mode
- After exiting gadget mode, Pico input works normally again

## First-Time Setup

Run the setup script to configure USB gadget mode:

```bash
cd ~/SamplePi
chmod +x usb_gadget/setup_usb_gadget.sh
./usb_gadget/setup_usb_gadget.sh
```

This will:
1. Create the storage image
2. Configure system files
3. Install the toggle script
4. Set up sudoers for passwordless toggle
5. Enable systemd services

After setup, use the **TOP button long-press** to toggle gadget mode.

## See Also

- [USAGE_GUIDE.md](USAGE_GUIDE.md) - Complete USB gadget usage guide
- [IMPLEMENTATION.md](IMPLEMENTATION.md) - Technical implementation details
- [../GPIO_CONFIGURATION.md](../GPIO_CONFIGURATION.md) - GPIO pin configuration
