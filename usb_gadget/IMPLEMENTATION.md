# SamplePi USB Gadget Mode Implementation

## Overview

This document describes the implementation of USB gadget mode for the SamplePi project, which allows the Raspberry Pi to appear as a USB mass storage device when connected to a computer. This enables easy file management of audio samples without requiring network connectivity.

## Components

### 1. Setup Script (`setup_usb_gadget.sh`)
- Configures the Raspberry Pi to operate in USB gadget mode
- Creates a virtual storage image file
- Modifies system configuration files (`/boot/config.txt` and `/boot/cmdline.txt`)
- Installs systemd services for automatic startup
- Creates utility scripts for safe eject and manual sync
- Updates the main SamplePi service to use production media paths

### 2. USB Gadget Configuration (`configure_usb_gadget.sh`)
- Sets up the Linux USB Gadget framework
- Configures the Pi as a mass storage device
- Links the virtual storage image to the USB interface

### 3. Media Path Configuration
- Uses environment variable `MEDIA_PATH_TYPE=production` to determine media directory
- When set to 'production', uses `/home/pi/media` as the media directory
- When unset or set to other values, uses the development path
- Allows the SamplePi application to access the same media files as exposed via USB gadget

### 4. Auto-sync Service (`autosync_service.sh`)
- Monitors the state of the USB gadget
- Automatically synchronizes files between the gadget storage and main media directories
- Prevents data loss when the gadget is disconnected
- Checks if SamplePi is running before performing sync operations

### 4. Systemd Services
- `usb-gadget.service`: Manages the USB gadget functionality
- `samplepi-gadget-sync.service`: Handles automatic synchronization

### 5. Utility Scripts
- `eject_usb_gadget.sh`: Safely disables the USB gadget
- `sync_media_to_gadget.sh`: Manually syncs media files to the gadget

## Technical Implementation

### System Configuration
The setup modifies two critical system files:

1. `/boot/config.txt` - Adds `dtoverlay=dwc2` to enable the USB controller in device mode
2. `/boot/cmdline.txt` - Adds `modules-load=dwc2,g_mass_storage` to load required modules at boot

### Virtual Storage Image
- A FAT32-formatted image file serves as the virtual storage device
- Size is calculated based on existing media content plus a buffer
- Contains organized directories matching the main media structure

### File Synchronization
- Bidirectional sync between main media directories and gadget storage
- Uses `rsync` with `--ignore-existing` to prevent overwrites
- Only syncs when SamplePi is not actively using the media files
- Automatic sync occurs when the gadget is disconnected

## Usage Workflow

### Initial Setup
1. Run `setup_usb_gadget.sh` as the pi user (not root)
2. Reboot the Raspberry Pi
3. The Pi will now operate as a USB gadget on boot

### Daily Operation
1. Connect the Pi to a computer via USB
2. The Pi appears as "SamplePi Media Storage" drive
3. Copy audio files to the appropriate directories
4. Safely eject the drive from the computer
5. Run `sudo eject_usb_gadget.sh` on the Pi for safe disconnection

### Manual Operations
- To sync files to gadget: `sudo sync_media_to_gadget.sh`
- To force sync from gadget: `sudo /home/pi/SamplePi/usb_gadget/autosync_service.sh sync-to-main`

## Safety Measures

### Process Checking
The system checks if SamplePi is running before performing any sync operations to prevent conflicts.

### Safe Disconnection
The eject script ensures all data is properly written before disabling the gadget.

### File Integrity
The sync process preserves existing files and only adds new ones to prevent accidental data loss.

## Limitations and Considerations

### Single-Function Constraint
- The Pi can only operate as one USB device function at a time
- USB gadget mode may conflict with other USB peripherals

### File Access During Gadget Mode
- The Pi cannot access the media directories directly while the gadget is active
- SamplePi application should not run while managing files via USB

### Storage Capacity
- The virtual storage image size is fixed at creation time
- May need to recreate the image if more space is needed

## Troubleshooting

### Pi Doesn't Appear as USB Drive
- Verify the correct USB port is used (OTG capable)
- Check that the Pi has fully booted
- Ensure the USB cable supports data transfer

### Sync Issues
- Check that SamplePi is not running during sync
- Verify file permissions on media directories
- Review log file at `/var/log/samplepi-gadget-sync.log`

### Service Failures
- Check systemd service status: `sudo systemctl status usb-gadget.service`
- Verify system configuration files weren't corrupted during setup