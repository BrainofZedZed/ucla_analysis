const int interval_check = 7;
const int IR_beam_check = 3;
const int reward_delivery = 4;
const int pin10 = 10;

// Define the intervals and set up tracking variables
const int VI_interval[] = {1, 4, 8, 12, 18, 24, 31, 41, 57, 99};
const int num_intervals = sizeof(VI_interval) / sizeof(VI_interval[0]);
int interval_index = 0;

unsigned long previousMillis = 0;
int currentInterval = 0;
bool VI_interval_selected = false;
bool rewardDelivered = false;
bool interval_check_active = false;
bool first_ttl = true;
bool change_interval_check = true;

void setup() {
    // Configure the pins

  pinMode(interval_check, OUTPUT);
  pinMode(IR_beam_check, INPUT);
  pinMode(reward_delivery, OUTPUT);
  pinMode(pin10, INPUT);
    // Initialize serial communication and the random seed
  digitalWrite(interval_check, LOW);
  digitalWrite(IR_beam_check, HIGH);
  digitalWrite(reward_delivery, HIGH);

  Serial.begin(9600);
  randomSeed(analogRead(0));
}

// Function to send data to the Python program over serial
void send_to_python(const char *pinName, int pin, int state) {
  Serial.print("{\"pin_name\": \"");
  Serial.print(pinName);
  Serial.print("\", \"pin\": ");
  Serial.print(pin);
  Serial.print(", \"state\": ");
  Serial.print(state);
  Serial.print(", \"time\": ");
  Serial.print(millis());
  Serial.println("}");
}

void loop() {
    // Check if pin10 is high
  if (digitalRead(pin10) == HIGH) {
    if (first_ttl == true) {
      send_to_python("start_ttl", pin10, HIGH);
      first_ttl = false;
    }
        // Select a new interval if one hasn't been chosen

    if (!VI_interval_selected) {
      currentInterval = VI_interval[interval_index];
      interval_index = (interval_index + 1) % num_intervals;
      VI_interval_selected = true;
      previousMillis = millis();
    }

    if (millis() - previousMillis >= (unsigned long)currentInterval * 1000) {
        if (change_interval_check) {
          digitalWrite(interval_check, HIGH);
          change_interval_check = false;
        }

      // Check if IR_beam_check is high
      if (digitalRead(IR_beam_check) == LOW) {
        // Deliver reward
        digitalWrite(reward_delivery, LOW);
        send_to_python("reward_delivery", reward_delivery, LOW);
        delay(600);
        digitalWrite(reward_delivery, HIGH);
        send_to_python("reward_delivery", reward_delivery, HIGH);
        // Set interval check to low
        digitalWrite(interval_check, LOW);
        send_to_python("interval_check", interval_check, LOW);
        VI_interval_selected = false;
        // Wait for 5 seconds
        delay(5000);
      }
    } else {
      change_interval_check = false;
    }

    int pins[] = {interval_check, IR_beam_check, reward_delivery};
    int num_pins = sizeof(pins) / sizeof(pins[0]);

    for (int i = 0; i < num_pins; i++) {
      int pin = pins[i];
      static int prevState[] = {LOW, HIGH, HIGH};
      int index = pin - 2;
      int currentState = digitalRead(pin);

      if (currentState != prevState[index]) {
        const char *pinName;

        switch (pin) {
          case interval_check:
            pinName = "interval_check";
            break;
          case IR_beam_check:
            pinName = "IR_beam_check";
            break;
          case reward_delivery:
            pinName = "reward_delivery";
            break;
        }

        send_to_python(pinName, pin, currentState);
        prevState[index] = currentState;
      }
    }
  }  else {
    digitalWrite(interval_check, LOW);
    digitalWrite(IR_beam_check, HIGH);
    digitalWrite(reward_delivery, HIGH);
  }   
}