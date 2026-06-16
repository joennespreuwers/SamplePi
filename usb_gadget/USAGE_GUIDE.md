# SamplePi USB Gadget Mode - Complete Guide

## Overview

The SamplePi USB Gadget Mode allows your Raspberry Pi to appear as a USB mass storage device when connected to a computer. This enables easy file management of audio samples without requiring network connectivity or SSH access.

## Features

- Appears as a standard USB mass storage device to any computer
- Contains organized directories for samples and test WAV files
- Preserves existing media when reconnecting
- Safe eject functionality to prevent data corruption
- Automatic synchronization between the gadget storage and main media directories
- Compatible with the production configuration of SamplePi

## Setup Instructions

### 1. Prepare Your Raspberry Pi

Before setting up the USB gadget functionality, ensure your Raspberry Pi is properly set up with SamplePi:

1. Follow the standard SamplePi installation process
2. Make sure the application is working correctly
3. Have your Raspberry Pi connected to the internet for the initial setup

### 2. Run the Setup Script

Connect to your Raspberry Pi via SSH or directly and navigate to the SamplePi directory:

```bash
cd ~/SamplePi
```

Run the USB gadget setup script:

```bash
chmod +x usb_gadget/setup_usb_gadget.sh
./usb_gadget/setup_usb_gadget.sh
```

Follow the prompts and wait for the setup to complete. The script will:
- Configure your Pi to operate in USB gadget mode
- Create a virtual storage image file
- Modify system configuration files
- Install systemd services for automatic startup
- Update the main SamplePi service to use production media paths
- Create utility scripts for safe eject and manual sync

### 3. Reboot Your Pi

After the setup completes, reboot your Raspberry Pi:

```bash
sudo reboot
```

## Usage Instructions

### Adding Samples to Your Pi

1. After the Pi reboots, connect it to your computer via USB
2. The Pi will appear as a USB drive named "SamplePi Media Storage"
3. Copy your WAV files to the appropriate directories:
   - `samples/` - For your custom samples
   - `test_wavs/` - For test WAV files
4. Safely eject the drive from your computer

### Safe Removal from Computer

To safely disconnect the Pi from the host computer:

```bash
sudo /usr/local/bin/eject_usb_gadget.sh
```

This ensures all data is properly written before disconnection.

### Manual Synchronization

If you need to manually sync files:

- To sync media files to the gadget: `sudo /usr/local/bin/sync_media_to_gadget.sh`
- To force sync from gadget to main: `sudo /home/pi/SamplePi/usb_gadget/autosync_service.sh sync-to-main`

### Checking Status

Use the debug script to check the status of the USB gadget:

```bash
sudo /home/pi/SamplePi/usb_gadget/debug_gadget.sh
```

## Technical Details

### Media Directory Configuration

The system uses an environment variable to determine which media directory to use:

- When `MEDIA_PATH_TYPE=production` (set in systemd service): uses `/home/pi/media`
- Otherwise (default): uses the development path

The USB gadget functionality works with the production configuration, exposing the same `/home/pi/media` directory structure.

### Auto-Synchronization

The system automatically synchronizes files in both directions:

- When the gadget is disconnected: files from the gadget storage are copied to the main media directories
- When the gadget is enabled: the latest files from the main directories are copied to the gadget storage
- Synchronization only occurs when SamplePi is not running to prevent conflicts

### File System

The virtual storage uses a FAT32 file system for maximum compatibility with different operating systems.

## Limitations

- While in gadget mode, the Pi cannot access the media directories directly
- The SamplePi application should not be running when managing files via USB
- Requires a reboot to enable the USB gadget functionality
- Only one USB device function can be active at a time
- The virtual storage image size is fixed at creation time

## Troubleshooting

### Pi doesn't appear as USB drive

- Ensure you're using the USB port capable of OTG (usually the power port on Pi Zero)
- Check that the Pi has fully booted after reboot
- Verify the USB cable supports data transfer (not just power)
- Run the debug script to check status: `sudo /home/pi/SamplePi/usb_gadget/debug_gadget.sh`

### Cannot write to the drive

- The drive might be mounted as read-only due to file system errors
- Try safely ejecting and reconnecting
- Run fsck on the image file if problems persist

### Files don't appear in SamplePi application

- Ensure the USB gadget is disconnected before running SamplePi
- The media directories are only synchronized when the gadget is disabled
- Check that the SamplePi service is configured with `MEDIA_PATH_TYPE=production`

### Sync issues

- Check that SamplePi is not running during sync
- Verify file permissions on media directories
- Review log file at `/var/log/samplepi-gadget-sync.log`

## Safety Measures

### Process Checking

The system checks if SamplePi is running before performing any sync operations to prevent conflicts.

### Safe Disconnection

The eject script ensures all data is properly written before disabling the gadget.

### File Integrity

The sync process preserves existing files and only adds new ones to prevent accidental data loss.

## System Integration

The USB gadget functionality integrates with the system through:

- `usb-gadget.service`: Manages the USB gadget functionality
- `samplepi-gadget-sync.service`: Handles automatic synchronization
- Updated `samplepi.service`: Configured to use production media paths

Both services start automatically when the system boots.