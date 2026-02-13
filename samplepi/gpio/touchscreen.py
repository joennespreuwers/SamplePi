"""Physical button input handler"""

try:
    from gpiozero import Button
    GPIO_AVAILABLE = True
except (ImportError, RuntimeError):
    GPIO_AVAILABLE = False
    print("Warning: GPIO not available. Physical buttons in mock mode.")

from samplepi.config import settings


class TouchscreenButtons:
    """Handles physical button input (single button for long press)"""

    def __init__(self):
        # Single button for long press functionality
        # Configure pin number in samplepi/config/settings.py
        LONG_PRESS_BUTTON_PIN = settings.LONG_PRESS_BUTTON_PIN

        self.gpio_available = GPIO_AVAILABLE

        if self.gpio_available:
            try:
                self.long_press_button = Button(LONG_PRESS_BUTTON_PIN)
            except Exception as e:
                print(f"Warning: Could not initialize long press button: {e}")
                self.gpio_available = False
                self.long_press_button = None
        else:
            self.long_press_button = None

        # Callbacks
        self._on_long_press_callback = None

        # Set up button callback if GPIO available
        if self.long_press_button:
            self.long_press_button.when_pressed = self._handle_long_press

    def _handle_long_press(self):
        """Internal handler for long press button"""
        if self._on_long_press_callback:
            self._on_long_press_callback()

    def on_long_press(self, callback):
        """Register callback for long press button"""
        self._on_long_press_callback = callback

    # Legacy methods for compatibility with existing code
    def on_top(self, callback):
        """No-op for compatibility"""
        pass

    def on_middle(self, callback):
        """No-op for compatibility"""
        pass

    def on_bottom(self, callback):
        """No-op for compatibility"""
        pass

    def on_left(self, callback):
        """No-op for compatibility"""
        pass

    def on_right(self, callback):
        """No-op for compatibility"""
        pass
