devices:

raspi

hifiberry dac pro xlr

rotary encoder

display hat with touchscreen 3.21in xpt2046

grpio out (100ms to high to simulate record button)

Goal of device:

Play wavs though a hifiberry and sends a gpio signal so that a camera starts recording.

interface that scrolls through files (like a 3d printer (ender for example)) with a rotary encoder

How:

menu on screen: start → select test wav (can be multiple) → select samples (can be multiple) → Want to video record? toggle →  press to start

 == Select is a short press, next is a long press, scroll to scroll through vstack menu

After this is done, a play again option or home.

3 buttons on the display when playing are for:

- pause/resume (this shoudnt affect the recording)
- stop test
- reset / reboot

3 buttons on the display for when not playing are:

- home
- nothing
- go back

For this project use python, first give me a overview of how you would handle this then we gradually start working on this.