"""Recording toggle screen"""

import pygame
from samplepi.ui.screen import Screen
from samplepi.config import settings


class RecordingToggleScreen(Screen):
    """Screen to toggle video recording on/off"""

    def __init__(self, app):
        super().__init__(app)

    def handle_scroll(self, direction):
        """Handle scroll input - toggle the setting"""
        self.app.state.record_video = not self.app.state.record_video

    def handle_select(self):
        """Handle select input - toggle recording"""
        self.app.state.record_video = not self.app.state.record_video

    def handle_button(self, button):
        """Handle button press"""
        if button == "left":  # Home
            from .start_screen import StartScreen
            self.app.state.go_home()
            self.app.state.goto_screen(StartScreen(self.app))
        elif button == "middle":  # Back
            self.app.state.go_back()
        elif button == "right":  # Next - go to confirm screen
            from .confirm_screen import ConfirmScreen
            self.app.state.goto_screen(ConfirmScreen(self.app))

    def render(self):
        """Render the screen"""
        self.screen.fill(settings.COLOR_BACKGROUND)
        self.draw_title("Video Recording")

        # Show summary of selections
        y = 70
        self.draw_text(f"Test WAVs: {len(self.app.state.selected_test_wavs)}", y, self.font_small)
        y += 20
        self.draw_text(f"Samples: {len(self.app.state.selected_samples)}", y, self.font_small)

        y += 40
        # Draw "Record Video" label
        self.draw_text("Record Video", y, self.font_medium)

        # Draw toggle switch
        y += 40
        self.draw_toggle_switch(y)

        self.draw_buttons(["Home", "Back", "Next"])

    def draw_toggle_switch(self, y):
        """Draw a toggle switch"""
        # Toggle switch dimensions
        switch_width = 80
        switch_height = 40
        switch_x = (settings.DISPLAY_WIDTH - switch_width) // 2

        # Draw switch background (track)
        track_rect = pygame.Rect(switch_x, y, switch_width, switch_height)
        track_color = settings.COLOR_HIGHLIGHT if self.app.state.record_video else (60, 60, 70)
        pygame.draw.rect(self.screen, track_color, track_rect, border_radius=switch_height // 2)
        pygame.draw.rect(self.screen, settings.COLOR_TEXT, track_rect, 2, border_radius=switch_height // 2)

        # Draw switch handle (thumb)
        handle_radius = switch_height // 2 - 4
        if self.app.state.record_video:
            handle_x = switch_x + switch_width - handle_radius - 8
        else:
            handle_x = switch_x + handle_radius + 8
        handle_y = y + switch_height // 2

        pygame.draw.circle(self.screen, (255, 255, 255), (handle_x, handle_y), handle_radius)
        pygame.draw.circle(self.screen, settings.COLOR_TEXT, (handle_x, handle_y), handle_radius, 2)

        # Draw ON/OFF text
        y += 60
        status_text = "ON" if self.app.state.record_video else "OFF"
        status_color = settings.COLOR_HIGHLIGHT if self.app.state.record_video else settings.COLOR_TEXT
        self.draw_text(status_text, y, self.font_medium, status_color)
