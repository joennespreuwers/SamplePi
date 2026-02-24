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
        
        # Title
        self.draw_text("USB TRANSFER MODE", 40, self.font_large, settings.COLOR_HIGHLIGHT)
        
        # Status indicator
        y = 90
        self.draw_text("● ACTIVE", y, self.font_medium, (0, 255, 0))
        
        # Instructions
        y = 130
        self.draw_text("Connect Pi to computer", y, self.font_small)
        y += 25
        self.draw_text("via USB port", y, self.font_small)
        
        y = 180
        self.draw_text("Transfer files to/from", y, self.font_small)
        y += 25
        self.draw_text("'SamplePi Media Storage'", y, self.font_small, settings.COLOR_HIGHLIGHT)
        
        # Blinking hint
        y = 220
        if self.text_visible:
            self.draw_text("Press TOP button (long)", y, self.font_small, settings.COLOR_BUTTON_ACTIVE)
            y += 20
            self.draw_text("to exit USB mode", y, self.font_small, settings.COLOR_BUTTON_ACTIVE)
        
        # Warning
        y = 20
        warning_text = "* Pico keyboard disabled in this mode"
        self.draw_text(warning_text, y, self.font_small, (255, 100, 100))
