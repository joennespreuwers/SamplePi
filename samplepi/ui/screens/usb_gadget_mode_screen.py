"""USB Gadget Mode indicator screen"""

import pygame
from samplepi.ui.screen import Screen
from samplepi.config import settings


class UsbGadgetModeScreen(Screen):
    """Screen shown when Pi is in USB gadget mode
    
    Displays instructions for file transfer and allows exiting gadget mode
    by pressing the top button (long press).
    """

    def __init__(self, app):
        super().__init__(app)
        self.blink_timer = 0
        self.text_visible = True

    def handle_select(self):
        """Handle select - no-op in gadget mode"""
        pass

    def handle_long_press(self):
        """Handle long press on top button - exit gadget mode"""
        # This will be handled by the GPIO callback directly
        pass

    def handle_top_button(self):
        """Handle short press on top button - go to home"""
        # In gadget mode, short press does nothing
        # Only long press (handled by callback) exits gadget mode
        pass

    def handle_middle_button(self):
        """Handle middle button - no-op in gadget mode"""
        pass

    def handle_bottom_button(self):
        """Handle bottom button - no-op in gadget mode"""
        pass

    def update(self):
        """Update screen state - blink hint text"""
        self.blink_timer += 1
        if self.blink_timer >= 30:  # Toggle every ~0.5 seconds
            self.text_visible = not self.text_visible
            self.blink_timer = 0

    def render(self):
        """Render the USB gadget mode screen"""
        self.screen.fill(settings.COLOR_BACKGROUND)

        # Warning bar (rendered first, at top)
        self.draw_text("* Pico keyboard disabled", 5, self.font_small, (255, 100, 100))

        # Title
        self.draw_text("USB TRANSFER MODE", 28, self.font_large, settings.COLOR_HIGHLIGHT)

        # Status indicator
        self.draw_text("● ACTIVE", 60, self.font_medium, (0, 255, 0))

        # Instructions
        y = 95
        self.draw_text("Connect Pi to computer", y, self.font_small)
        y += 22
        self.draw_text("via USB port", y, self.font_small)

        y = 145
        self.draw_text("Transfer files to/from", y, self.font_small)
        y += 22
        self.draw_text("'SamplePi Media Storage'", y, self.font_small, settings.COLOR_HIGHLIGHT)

        # Blinking hint at bottom
        if self.text_visible:
            self.draw_text("Hold TOP button to exit", 195, self.font_small, settings.COLOR_BUTTON_ACTIVE)
