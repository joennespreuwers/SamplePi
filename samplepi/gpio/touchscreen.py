"""Physical button input handler"""

try:
    from gpiozero import Button
    GPIO_AVAILABLE = True
except (ImportError, RuntimeError):
    GPIO_AVAILABLE = False
    print("Warning: GPIO not available. Physical buttons in mock mode.")

from samplepi.config import settings


class TouchscreenButtons:
    """Handles physical button input (3 buttons on left side: top, middle, bottom)"""

    def __init__(self):
        # Physical buttons on left side of display (top to bottom)
        # Configure pin numbers in mediaplayer/config/settings.py
        TOP_BUTTON_PIN = settings.BUTTON_TOP_PIN
        MIDDLE_BUTTON_PIN = settings.BUTTON_MIDDLE_PIN
        BOTTOM_BUTTON_PIN = settings.BUTTON_BOTTOM_PIN

        self.gpio_available = GPIO_AVAILABLE

        if self.gpio_available:
            try:
                self.top_button = Button(TOP_BUTTON_PIN)
                self.middle_button = Button(MIDDLE_BUTTON_PIN)
                self.bottom_button = Button(BOTTOM_BUTTON_PIN)
            except Exception as e:
                print(f"Warning: Could not initialize physical buttons: {e}")
                self.gpio_available = False
                self.top_button = None
                self.middle_button = None
                self.bottom_button = None
        else:
            self.top_button = None
            self.middle_button = None
            self.bottom_button = None

        # Callbacks
        self._on_top_callback = None
        self._on_middle_callback = None
        self._on_bottom_callback = None

        # Set up button callbacks if GPIO available
        if self.top_button:
            self.top_button.when_pressed = self._handle_top
        if self.middle_button:
            self.middle_button.when_pressed = self._handle_middle
        if self.bottom_button:
            self.bottom_button.when_pressed = self._handle_bottom

    def _handle_top(self):
        """Internal handler for top button"""
        if self._on_top_callback:
            self._on_top_callback()

    def _handle_middle(self):
        """Internal handler for middle button"""
        if self._on_middle_callback:
            self._on_middle_callback()

    def _handle_bottom(self):
        """Internal handler for bottom button"""
        if self._on_bottom_callback:
            self._on_bottom_callback()

    def on_top(self, callback):
        """Register callback for top button (mapped to 'left' in UI)"""
        self._on_top_callback = callback

    def on_middle(self, callback):
        """Register callback for middle button"""
        self._on_middle_callback = callback

    def on_bottom(self, callback):
        """Register callback for bottom button (mapped to 'right' in UI)"""
        self._on_bottom_callback = callback

    # Legacy methods for compatibility with existing code
    def on_left(self, callback):
        """Alias for on_top()"""
        self.on_top(callback)

    def on_right(self, callback):
        """Alias for on_bottom()"""
        self.on_bottom(callback)
