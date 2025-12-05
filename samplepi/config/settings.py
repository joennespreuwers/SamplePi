"""Configuration settings for MediaPlayer"""

# Display settings
DISPLAY_WIDTH = 480
DISPLAY_HEIGHT = 320
FPS = 30

# GPIO Pin assignments (BCM numbering)
ROTARY_CLK_PIN = 17  # Rotary encoder clock
ROTARY_DT_PIN = 27   # Rotary encoder data
ROTARY_SW_PIN = 22   # Rotary encoder switch/button

# Physical buttons on left side of display (top to bottom)
BUTTON_TOP_PIN = 5      # Top button (Home)
BUTTON_MIDDLE_PIN = 6   # Middle button (Next/Action)
BUTTON_BOTTOM_PIN = 13  # Bottom button (Back)

CAMERA_TRIGGER_PIN = 23  # GPIO output for camera trigger
CAMERA_TRIGGER_DURATION = 0.1  # 100ms pulse duration

# Audio settings
AUDIO_SAMPLE_RATE = 44100
AUDIO_BUFFER_SIZE = 2048

# File paths
import os
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MEDIA_ROOT = os.path.join(PROJECT_ROOT, "test_media")  # For development
# MEDIA_ROOT = "/home/pi/media"  # Uncomment for production on Pi
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
