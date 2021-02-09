#include <SoftwareSerial.h>
#include <Servo.h>

int software_tx = 2;
int software_rx = 3;
SoftwareSerial BLE(software_rx, software_tx);
int state = LOW;
Servo myservo;


void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  BLE.begin(9600);
  Serial.println("Start to listen from Bluetooth.");
  myservo.attach(9);
}

void loop() {
  String instruction = get_instruction();
  if (instruction.length() != 0) {
    Serial.println(instruction); 

    if (state == LOW && instruction == "ON") {
      myservo.write(45);
      state = HIGH;
    } else if (state == HIGH && instruction == "OFF") {
      myservo.write(0);
      state = LOW;
    } else {
      state = LOW;
    }
  
    if (state == LOW) {
      Serial.println("state is low");
    } else {
      Serial.println("state is high");
    }
  }

  
  delay(100);
}

  

String get_instruction() {
  String instruction = "";
  char ins_chars[20];
  int i = 0;
  while (BLE.available()) {
    ins_chars[i] = BLE.read();
    i++;
  }
  ins_chars[i] = '\0';
  if (strlen(ins_chars) > 0) {
    instruction = (String) ins_chars;
  }
  return instruction;
}
