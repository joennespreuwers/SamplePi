"""Generate test WAV files for development"""
import wave
import math
import struct
import os

def generate_sine_wave(filename, frequency, duration=2.0, sample_rate=44100):
    """Generate a sine wave WAV file"""
    num_samples = int(duration * sample_rate)

    with wave.open(filename, 'w') as wav_file:
        # Set parameters: nchannels, sampwidth, framerate, nframes, comptype, compname
        wav_file.setparams((2, 2, sample_rate, num_samples, 'NONE', 'not compressed'))

        for i in range(num_samples):
            # Generate sine wave
            value = int(32767.0 * math.sin(2.0 * math.pi * frequency * i / sample_rate))
            # Write stereo (same value for both channels)
            data = struct.pack('<hh', value, value)
            wav_file.writeframes(data)

# Create test_wavs directory
os.makedirs('test_media/test_wavs', exist_ok=True)
os.makedirs('test_media/samples', exist_ok=True)

# Generate test WAV files
print("Generating test WAV files...")
generate_sine_wave('test_media/test_wavs/440hz_test.wav', 440, 2.0)
print("  Created: 440hz_test.wav (A4 note, 2 seconds)")

generate_sine_wave('test_media/test_wavs/880hz_test.wav', 880, 2.0)
print("  Created: 880hz_test.wav (A5 note, 2 seconds)")

generate_sine_wave('test_media/test_wavs/220hz_test.wav', 220, 2.0)
print("  Created: 220hz_test.wav (A3 note, 2 seconds)")

# Generate sample files
print("\nGenerating sample files...")
generate_sine_wave('test_media/samples/1khz_sample.wav', 1000, 3.0)
print("  Created: 1khz_sample.wav (1kHz tone, 3 seconds)")

generate_sine_wave('test_media/samples/500hz_sample.wav', 500, 3.0)
print("  Created: 500hz_sample.wav (500Hz tone, 3 seconds)")

print("\nAll test files created successfully!")
