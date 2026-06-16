// Blink sketch for Raspberry Pi Pico
// The onboard LED is connected to GPIO 25

void setup() {
  // Initialize the LED pin as an output
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
  digitalWrite(LED_BUILTIN, HIGH);  // Turn the LED on
  delay(1000);                       // Wait for 1 second
  digitalWrite(LED_BUILTIN, LOW);   // Turn the LED off
  delay(1000);                       // Wait for 1 second
}
