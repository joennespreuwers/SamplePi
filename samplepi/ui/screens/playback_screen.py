"""Playback screen"""

import pygame
import os
from samplepi.ui.screen import Screen
from samplepi.config import settings


class PlaybackScreen(Screen):
    """Screen shown during playback"""

    def __init__(self, app):
        super().__init__(app)
        self.app.state.is_playing = True
        self.app.state.is_paused = False
        self.status_message = "Playing..."

        # Build playlist from selected files
        playlist = []
        for wav in self.app.state.selected_test_wavs:
            playlist.append(os.path.join(settings.TEST_WAVS_DIR, wav))
        for sample in self.app.state.selected_samples:
            playlist.append(os.path.join(settings.SAMPLES_DIR, sample))

        # Load playlist and start playback
        self.app.audio_player.load_playlist(playlist)
        self.app.audio_player.play()

        # Trigger camera if recording enabled
        if self.app.state.record_video:
            self.app.camera_trigger.send_pulse()
            self.status_message = "Recording started..."

    def handle_button(self, button):
        """Handle button press"""
        if button == "left":  # Pause/Resume
            self.toggle_pause()
        elif button == "middle":  # Reset/Reboot
            self.reset()
        elif button == "right":  # Stop
            self.stop_playback()

    def toggle_pause(self):
        """Toggle pause/resume (does NOT affect recording)"""
        self.app.state.is_paused = not self.app.state.is_paused
        if self.app.state.is_paused:
            self.app.audio_player.pause()
            self.status_message = "Paused"
        else:
            self.app.audio_player.resume()
            self.status_message = "Playing..."

    def stop_playback(self):
        """Stop playback and show completion screen"""
        self.app.state.is_playing = False
        self.app.audio_player.stop()
        from .complete_screen import CompleteScreen
        self.app.state.goto_screen(CompleteScreen(self.app))

    def reset(self):
        """Reset to home screen"""
        self.app.state.is_playing = False
        self.app.audio_player.stop()
        from .start_screen import StartScreen
        self.app.state.go_home()
        self.app.state.goto_screen(StartScreen(self.app))

    def update(self):
        """Update playback state"""
        # Check if current track finished
        if not self.app.audio_player.is_busy() and self.app.state.is_playing and not self.app.state.is_paused:
            # Try to play next track
            if not self.app.audio_player.next_track():
                # Playlist finished
                self.stop_playback()

    def render(self):
        """Render the screen"""
        self.screen.fill(settings.COLOR_BACKGROUND)
        self.draw_title("Playback")

        y = 80
        # Show status
        status_color = settings.COLOR_HIGHLIGHT if not self.app.state.is_paused else settings.COLOR_TEXT
        self.draw_text(self.status_message, y, self.font_large, status_color)

        y += 60
        # Show current file info
        progress = self.app.audio_player.get_progress()
        current_file = progress['current_file'] or "..."
        self.draw_text(current_file, y, self.font_small)

        y += 30
        file_count_text = f"File {progress['current_index'] + 1} of {progress['total_files']}"
        self.draw_text(file_count_text, y, self.font_medium)

        y += 40
        # Draw progress bar
        if progress['total_files'] > 0:
            self.draw_progress_bar(y, progress['current_index'], progress['total_files'])
            y += 40

        if self.app.state.record_video:
            self.draw_text("Camera Recording Active", y, self.font_small, settings.COLOR_HIGHLIGHT)

        # Show playback controls
        pause_label = "Resume" if self.app.state.is_paused else "Pause"
        self.draw_buttons([pause_label, "Reset", "Stop"])

    def draw_progress_bar(self, y, current, total):
        """Draw a visual progress bar"""
        bar_width = 400
        bar_height = 20
        bar_x = (settings.DISPLAY_WIDTH - bar_width) // 2

        # Draw background
        bg_rect = pygame.Rect(bar_x, y, bar_width, bar_height)
        pygame.draw.rect(self.screen, (40, 40, 50), bg_rect)
        pygame.draw.rect(self.screen, settings.COLOR_TEXT, bg_rect, 1)

        # Draw progress
        if total > 0:
            progress_width = int((current / total) * bar_width)
            progress_rect = pygame.Rect(bar_x, y, progress_width, bar_height)
            pygame.draw.rect(self.screen, settings.COLOR_HIGHLIGHT, progress_rect)
