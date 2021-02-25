#include <SoftwareSerial.h>

// Bluetooth communication pins
int software_tx = 2;
int software_rx = 3;
SoftwareSerial BLE(software_rx, software_tx);

// Movement sensor pins
int sensorIn = 8;
int lightOut = 9;

// Conditions
int state = LOW;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  BLE.begin(9600);
  pinMode(sensorIn, INPUT);
  pinMode(lightOut, OUTPUT);
}

void loop() {
  String instruction = get_instruction();
  bool moveSignal = get_moveSignal();

  // send current ON/OFF status to my phone when my phone connects
  // to the Bluetooth
  if (instruction == "+CONNECTED") {
    if (state == HIGH) {
      BLE.write("ON");
    } else {
      BLE.write("OFF");
    }
  }

  // whenever receive the instruction from my phone or capture 
  // a movement, switch the light status
  if ((instruction == "ON" || moveSignal) && state == LOW) {
    state = HIGH;
    BLE.write("ON");
  } else if ((instruction == "OFF" || moveSignal) && state == HIGH) {
    state = LOW;
    BLE.write("OFF");
  }

  // actual place to turn on/off the light
  digitalWrite(lightOut, state);

  // debounce the movement, only two consecutive moments with 
  // 500 ms apart can be captured.
  if (moveSignal) {
    delay(500);
  }
}

// capture the movement
bool get_moveSignal() {
  if (digitalRead(sensorIn) == LOW) {
    return true;
  } else {
    return false;
  }
}
 
// "decode" bluetooth communication and parse the instruction 
String get_instruction() {
  String instruction = "";
  char ins_chars[20];
  char char_i;
  int i = 0;
  while (BLE.available()) {
    char_i = BLE.read();
    int char_int = int(char_i);
    // here is to filter out unreadable characters
    if (char_int < 32 || char_int > 127) {
      break;
    }
    ins_chars[i] = char_i;
    i++;
    delay(20); // wait for the next character to be captured
  }
  ins_chars[i] = '\0';
  if (strlen(ins_chars) > 0) {
    instruction = (String) ins_chars;
  }

  if (instruction.length() != 0) {
    Serial.println(instruction);
  }

  return instruction;
}
