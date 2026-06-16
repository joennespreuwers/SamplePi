"""Application state manager"""


class AppState:
    """Manages application state and screen transitions"""

    def __init__(self):
        self.current_screen = None
        self.screen_history = []

        # User selections
        self.selected_test_wavs = []
        self.selected_samples = []
        self.record_video = False

        # Playback state
        self.is_playing = False
        self.is_paused = False

    def goto_screen(self, screen):
        """Navigate to a new screen"""
        if self.current_screen:
            self.screen_history.append(self.current_screen)
        self.current_screen = screen

    def go_back(self):
        """Go back to previous screen"""
        if self.screen_history:
            self.current_screen = self.screen_history.pop()
            return True
        return False

    def go_home(self):
        """Go to home screen (clear history)"""
        self.screen_history.clear()
        # Current screen will be set to home by caller

    def reset_selections(self):
        """Reset all user selections"""
        self.selected_test_wavs = []
        self.selected_samples = []
        self.record_video = False
