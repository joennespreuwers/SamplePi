"""Configuration settings for MediaPlayer"""

import os

# Display settings (Waveshare 3.2" LCD is 320x240)
DISPLAY_WIDTH = 320
DISPLAY_HEIGHT = 240
FPS = 30

# Framebuffer device for direct rendering (no X11/desktop required).
# The Waveshare SPI LCD typically shows up as /dev/fb1 alongside the
# Pi's HDMI framebuffer (/dev/fb0). Override with SAMPLEPI_FBDEV if needed.
FRAMEBUFFER_DEVICE = os.environ.get("SAMPLEPI_FBDEV", "/dev/fb1")

# GPIO Pin assignments (BCM numbering)
# Using pins that don't conflict with SPI display and XPT2046 touch controller
ROTARY_CLK_PIN = 12  # Rotary encoder clock (PWM0 - safe pin)
ROTARY_DT_PIN = 13   # Rotary encoder data (PWM1 - safe pin, was BUTTON_BOTTOM_PIN)
ROTARY_SW_PIN = 16   # Rotary encoder switch/button (CE2 - safe pin)

# Single button for long press functionality
LONG_PRESS_BUTTON_PIN = 6  # Middle button position (Next/Action/Long Press)

CAMERA_TRIGGER_PIN = 26  # GPIO output for camera trigger
CAMERA_TRIGGER_DURATION = 0.1  # 100ms pulse duration

# Audio settings
AUDIO_SAMPLE_RATE = 44100
AUDIO_BUFFER_SIZE = 2048

# File paths
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Check if running in production mode
if os.environ.get('MEDIA_PATH_TYPE') == 'production':
    MEDIA_ROOT = "/home/pi/media"  # Production media path
else:
    MEDIA_ROOT = os.path.join(PROJECT_ROOT, "test_media")  # For development

TEST_WAVS_DIR = os.path.join(MEDIA_ROOT, "test_wavs")
SAMPLES_DIR = os.path.join(MEDIA_ROOT, "samples")

# UI settings
BUTTON_HEIGHT = 60
FONT_SIZE_LARGE = 24
FONT_SIZE_MEDIUM = 18
FONT_SIZE_SMALL = 14

# Colors (R, G, B)
COLOR_BACKGROUND = (20, 20, 30)
COLOR_TEXT = (255, 255, 255)
COLOR_BUTTON = (60, 60, 80)
COLOR_BUTTON_ACTIVE = (80, 100, 140)
COLOR_HIGHLIGHT = (100, 150, 255)

# Menu pagination
ITEMS_PER_PAGE = 5
