#include <Keyboard.h>

// Pin definitions for rotary encoder
const int CLK_PIN = 2;    // Encoder CLK (A phase)
const int DT_PIN = 3;     // Encoder DT (B phase)
const int SW_PIN = 4;     // Encoder button/switch

// Encoder state variables
volatile int lastCLK = HIGH;
volatile bool rotated = false;
volatile int direction = 0; // 1 for clockwise, -1 for counter-clockwise

// Button state variables
unsigned long buttonPressTime = 0;
bool buttonPressed = false;
bool buttonHandled = false;
const unsigned long LONG_PRESS_TIME = 500; // 500ms for long press
const unsigned long DEBOUNCE_DELAY = 50;    // 50ms debounce

void setup() {
  // Initialize encoder pins
  pinMode(CLK_PIN, INPUT_PULLUP);
  pinMode(DT_PIN, INPUT_PULLUP);
  pinMode(SW_PIN, INPUT_PULLUP);

  // Initialize USB keyboard
  Keyboard.begin();

  // Read initial state
  lastCLK = digitalRead(CLK_PIN);

  // Small delay to ensure stable startup
  delay(100);
}

void loop() {
  // Handle rotary encoder rotation
  handleEncoder();

  // Handle button press
  handleButton();

  // Small delay to prevent excessive polling
  delay(1);
}

void handleEncoder() {
  int currentCLK = digitalRead(CLK_PIN);

  // Check if CLK state has changed (falling edge detection)
  if (currentCLK != lastCLK && currentCLK == LOW) {
    int dtValue = digitalRead(DT_PIN);

    // Determine direction based on DT state when CLK falls
    if (dtValue != currentCLK) {
      // Clockwise rotation - send DOWN arrow
      Keyboard.press(KEY_DOWN_ARROW);
      delay(10);
      Keyboard.releaseAll();
      delay(50); // Debounce delay
    } else {
      // Counter-clockwise rotation - send UP arrow
      Keyboard.press(KEY_UP_ARROW);
      delay(10);
      Keyboard.releaseAll();
      delay(50); // Debounce delay
    }
  }

  lastCLK = currentCLK;
}

void handleButton() {
  int buttonState = digitalRead(SW_PIN);

  // Button pressed (active LOW with pullup)
  if (buttonState == LOW) {
    if (!buttonPressed) {
      // Button just pressed
      buttonPressed = true;
      buttonPressTime = millis();
      buttonHandled = false;
    } else if (!buttonHandled && (millis() - buttonPressTime >= LONG_PRESS_TIME)) {
      // Long press detected - send 'L' key
      Keyboard.press('l');
      delay(10);
      Keyboard.releaseAll();
      buttonHandled = true;
    }
  } else {
    // Button released
    if (buttonPressed && !buttonHandled) {
      // Short press detected - send ENTER key
      if (millis() - buttonPressTime < LONG_PRESS_TIME) {
        Keyboard.press(KEY_RETURN);
        delay(10);
        Keyboard.releaseAll();
      }
    }

    // Reset button state
    buttonPressed = false;
    buttonHandled = false;
  }
}
