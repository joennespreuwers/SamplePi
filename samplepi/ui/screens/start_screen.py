"""Start/Home screen"""

import pygame
from samplepi.ui.screen import Screen
from samplepi.ui.menu_list import MenuList
from samplepi.config import settings


class StartScreen(Screen):
    """Initial start screen"""

    def __init__(self, app):
        super().__init__(app)
        self.menu = MenuList(["Start New Session"])

    def handle_scroll(self, direction):
        """Handle scroll input"""
        self.menu.scroll(direction)

    def handle_select(self):
        """Handle select input"""
        selected = self.menu.get_selected()
        if selected == "Start New Session":
            # Reset selections and go to test WAV selection
            self.app.state.reset_selections()
            from .file_selection_screen import FileSelectionScreen
            self.app.state.goto_screen(
                FileSelectionScreen(self.app, "test_wavs", "Select Test WAV Files")
            )

    def handle_button(self, button):
        """Handle button press"""
        if button == "left":  # Home (already at home)
            pass
        elif button == "middle":  # Back (stays on home)
            pass
        elif button == "right":  # Next - start new session
            self.handle_select()

    def render(self):
        """Render the screen"""
        self.screen.fill(settings.COLOR_BACKGROUND)
        self.draw_title("SamplePi")
        self.menu.render(self.screen, self.font_medium)
        self.draw_buttons(["Home", None, "Start"])
