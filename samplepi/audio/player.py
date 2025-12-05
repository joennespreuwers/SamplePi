"""Audio playback engine using pygame.mixer"""

import pygame
import os
from samplepi.config import settings


class AudioPlayer:
    """Handles audio playback of WAV files"""

    def __init__(self):
        """Initialize the audio player"""
        # Initialize pygame mixer
        pygame.mixer.init(
            frequency=settings.AUDIO_SAMPLE_RATE,
            size=-16,
            channels=2,
            buffer=settings.AUDIO_BUFFER_SIZE
        )

        self.playlist = []
        self.current_index = 0
        self.is_playing = False
        self.is_paused = False

    def load_playlist(self, file_paths):
        """Load a playlist of WAV files"""
        self.playlist = file_paths
        self.current_index = 0

    def play(self):
        """Start playback from current position"""
        if not self.playlist:
            return False

        if self.is_paused:
            # Resume from pause
            pygame.mixer.music.unpause()
            self.is_paused = False
            self.is_playing = True
            return True

        # Load and play current file
        if self.current_index < len(self.playlist):
            file_path = self.playlist[self.current_index]
            try:
                pygame.mixer.music.load(file_path)
                pygame.mixer.music.play()
                self.is_playing = True
                self.is_paused = False
                return True
            except pygame.error as e:
                print(f"Error playing {file_path}: {e}")
                return False

        return False

    def pause(self):
        """Pause playback"""
        if self.is_playing and not self.is_paused:
            pygame.mixer.music.pause()
            self.is_paused = True

    def resume(self):
        """Resume from pause"""
        if self.is_paused:
            pygame.mixer.music.unpause()
            self.is_paused = False

    def stop(self):
        """Stop playback"""
        pygame.mixer.music.stop()
        self.is_playing = False
        self.is_paused = False

    def next_track(self):
        """Move to next track in playlist"""
        if self.current_index < len(self.playlist) - 1:
            self.stop()
            self.current_index += 1
            return self.play()
        return False

    def is_busy(self):
        """Check if audio is currently playing"""
        return pygame.mixer.music.get_busy()

    def get_current_file(self):
        """Get current playing file name"""
        if 0 <= self.current_index < len(self.playlist):
            return os.path.basename(self.playlist[self.current_index])
        return None

    def get_progress(self):
        """Get playback progress"""
        return {
            'current_index': self.current_index,
            'total_files': len(self.playlist),
            'is_playing': self.is_playing,
            'is_paused': self.is_paused,
            'current_file': self.get_current_file()
        }

    def cleanup(self):
        """Clean up audio resources"""
        self.stop()
        pygame.mixer.quit()
