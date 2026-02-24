"""Physical button input handler"""

import time
import threading

try:
    from gpiozero import Button
    GPIO_AVAILABLE = True
except (ImportError, RuntimeError):
    GPIO_AVAILABLE = False
    print("Warning: GPIO not available. Physical buttons in mock mode.")

from samplepi.config import settings


class TouchscreenButtons:
    """Handles physical button input from 3 buttons on left side of display
    
    Button layout (top to bottom):
    - Top button (GPIO 5): Home / USB Gadget Mode toggle (long press)
    - Middle button (GPIO 6): Pause/Resume during playback
    - Bottom button (GPIO 19): Back / Stop during playback
    """

    def __init__(self, long_press_duration=1.0):
        self.gpio_available = GPIO_AVAILABLE
        
        # Long press detection for top button (USB gadget toggle)
        self.long_press_duration = long_press_duration
        self._top_press_start_time = None
        self._top_long_press_triggered = False
        self._top_press_timer = None
        
        # Button instances
        self.top_button = None
        self.middle_button = None
        self.bottom_button = None

        # Callbacks
        self._on_top_callback = None
        self._on_middle_callback = None
        self._on_bottom_callback = None
        self._on_top_long_press_callback = None  # USB gadget toggle
        self._on_long_press_callback = None  # Legacy callback

        if self.gpio_available:
            try:
                # Initialize top button (GPIO 5) - Home / USB Gadget toggle
                self.top_button = Button(settings.BUTTON_TOP_PIN, pull_up=True)
                self.top_button.when_pressed = self._handle_top_pressed
                self.top_button.when_released = self._handle_top_released
                
                # Initialize middle button (GPIO 6) - Pause/Resume
                self.middle_button = Button(settings.BUTTON_MIDDLE_PIN, pull_up=True)
                self.middle_button.when_pressed = self._handle_middle_pressed
                
                # Initialize bottom button (GPIO 19) - Back/Stop
                self.bottom_button = Button(settings.BUTTON_BOTTOM_PIN, pull_up=True)
                self.bottom_button.when_pressed = self._handle_bottom_pressed
                
            except Exception as e:
                print(f"Warning: Could not initialize touchscreen buttons: {e}")
                self.gpio_available = False
        else:
            print("Running in mock GPIO mode - buttons not available")

    def _handle_top_pressed(self):
        """Handle top button press - start timer for long press detection"""
        self._top_press_start_time = time.time()
        self._top_long_press_triggered = False
        
        # Start timer for long press detection (USB gadget toggle)
        if self._top_press_timer:
            self._top_press_timer.cancel()
        self._top_press_timer = threading.Timer(
            self.long_press_duration, 
            self._trigger_top_long_press
        )
        self._top_press_timer.start()

    def _handle_top_released(self):
        """Handle top button release - short press = Home, long press = USB gadget toggle"""
        # Cancel long press timer
        if self._top_press_timer:
            self._top_press_timer.cancel()
            self._top_press_timer = None
        
        # If long press wasn't triggered, treat as short press (Home)
        if not self._top_long_press_triggered and self._on_top_callback:
            self._on_top_callback()
        
        self._top_press_start_time = None
        self._top_long_press_triggered = False

    def _trigger_top_long_press(self):
        """Trigger long press callback for top button (USB gadget toggle)"""
        self._top_long_press_triggered = True
        if self._on_top_long_press_callback:
            self._on_top_long_press_callback()

    def _handle_middle_pressed(self):
        """Handle middle button press - Pause/Resume"""
        if self._on_middle_callback:
            self._on_middle_callback()

    def _handle_bottom_pressed(self):
        """Handle bottom button press - Back/Stop"""
        if self._on_bottom_callback:
            self._on_bottom_callback()

    # Public callback registration methods
    def on_top(self, callback):
        """Register callback for top button short press (Home)"""
        self._on_top_callback = callback

    def on_middle(self, callback):
        """Register callback for middle button press (Pause/Resume)"""
        self._on_middle_callback = callback

    def on_bottom(self, callback):
        """Register callback for bottom button press (Back/Stop)"""
        self._on_bottom_callback = callback

    def on_top_long_press(self, callback):
        """Register callback for top button long press (USB Gadget Mode toggle)"""
        self._on_top_long_press_callback = callback

    # Legacy callback support
    def on_long_press(self, callback):
        """Register callback for long press (legacy - maps to middle button)"""
        self._on_long_press_callback = callback
        # Also map to middle button for backward compatibility
        if self.middle_button:
            self.middle_button.when_held = callback

    def cleanup(self):
        """Clean up GPIO resources"""
        if self._top_press_timer:
            self._top_press_timer.cancel()
            self._top_press_timer = None
        
        if self.gpio_available:
            if self.top_button:
                self.top_button.close()
            if self.middle_button:
                self.middle_button.close()
            if self.bottom_button:
                self.bottom_button.close()
