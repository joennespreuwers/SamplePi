"""Playback complete screen"""

import pygame
from samplepi.ui.screen import Screen
from samplepi.ui.menu_list import MenuList
from samplepi.config import settings


class CompleteScreen(Screen):
    """Screen shown after playback completes"""

    def __init__(self, app):
        super().__init__(app)
        self.menu = MenuList(["Play Again", "Return to Home"])

    def handle_scroll(self, direction):
        """Handle scroll input"""
        self.menu.scroll(direction)

    def handle_select(self):
        """Handle select input"""
        selected = self.menu.get_selected()
        if selected == "Play Again":
            # Go back to recording toggle to ask about camera again
            from .recording_toggle_screen import RecordingToggleScreen
            self.app.state.goto_screen(RecordingToggleScreen(self.app))
        elif selected == "Return to Home":
            from .start_screen import StartScreen
            self.app.state.go_home()
            self.app.state.goto_screen(StartScreen(self.app))

    def handle_long_press(self):
        """Handle long press - execute selected option"""
        self.handle_select()

    def render(self):
        """Render the screen"""
        self.screen.fill(settings.COLOR_BACKGROUND)
        self.draw_title("Playback Complete")

        self.draw_text("Session finished successfully", 70, self.font_medium, settings.COLOR_HIGHLIGHT)

        self.menu.render(self.screen, self.font_medium)
