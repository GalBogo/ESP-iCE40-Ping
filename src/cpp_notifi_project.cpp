#include <Arduino.h>
#include <WiFi.h>
#include <WebServer.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

#define MSG_PIN 16
#define CALL_PIN 4

const char* ssid = "Gal_Dana 2.4"; 
const char* password = "207152901s";

WebServer server(80);

enum DisplayState { IDLE, MESSAGE, CALL };
DisplayState currentState = IDLE;

String currentText = "";
unsigned long messageStartTime = 0;
unsigned long callStartTime = 0;
unsigned long lastBlinkTime = 0;
bool isBlinking = false;

String cleanString(String raw) {
  String clean = "";
  for (int i = 0; i < raw.length(); i++) {
    char c = raw[i];
    if (c >= 32 && c <= 126) clean += c;
  }
  return clean;
}

void handleMessage() {
  if (server.hasArg("text")) {
    currentText = cleanString(server.arg("text"));
    currentState = MESSAGE;
    digitalWrite(MSG_PIN, HIGH);
    digitalWrite(CALL_PIN, LOW);
    messageStartTime = millis(); 
    server.send(200, "text/plain", "OK");
  } else {
    server.send(400, "text/plain", "Bad Request");
  }
}

void handleCall() {
  if (server.hasArg("name")) {
    currentText = cleanString(server.arg("name"));
    currentState = CALL;
    digitalWrite(CALL_PIN, HIGH);
    digitalWrite(MSG_PIN, LOW);
    callStartTime = millis();
    server.send(200, "text/plain", "OK");
  } else {
    server.send(400, "text/plain", "Bad Request");
  }
}

void handleIdle() {
  currentState = IDLE; 
  digitalWrite(MSG_PIN, LOW);
  digitalWrite(CALL_PIN, LOW);
  server.send(200, "text/plain", "OK");
}

void setup() {
  Serial.begin(115200);
  
  pinMode(MSG_PIN, OUTPUT);
  pinMode(CALL_PIN, OUTPUT);
  digitalWrite(MSG_PIN, LOW);
  digitalWrite(CALL_PIN, LOW);

  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    for(;;);
  }
  
  display.clearDisplay();
  display.setTextSize(2);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println("Connecting Wi-Fi...");
  display.display();

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
  }

  display.clearDisplay();
  display.setCursor(0, 0);
  display.println("Connected!");
  display.println(WiFi.localIP());
  display.display();
  delay(2000);

  server.on("/message", handleMessage);
  server.on("/call", handleCall);
  server.on("/idle", handleIdle);
  server.begin();
}

void drawEyes() {
  display.clearDisplay();
  
  if (millis() - lastBlinkTime > (isBlinking ? 200 : 3000)) {
    isBlinking = !isBlinking;
    lastBlinkTime = millis();
  }
  
  if (isBlinking) {
    display.fillRect(20, 30, 28, 4, SSD1306_WHITE);
    display.fillRect(80, 30, 28, 4, SSD1306_WHITE);
  } else {
    display.drawRoundRect(20, 16, 28, 28, 6, SSD1306_WHITE);
    display.drawRoundRect(80, 16, 28, 28, 6, SSD1306_WHITE);
    
    display.fillRect(28, 24, 12, 12, SSD1306_WHITE);
    display.fillRect(88, 24, 12, 12, SSD1306_WHITE);
  }
  display.display();
}

void loop() {
  server.handleClient();
  
  if (currentState == IDLE) {
    drawEyes();
  } 
  else if (currentState == MESSAGE) {
    display.clearDisplay();
    display.setCursor(0, 0);
    
    int colonIndex = currentText.indexOf(':');
    if (colonIndex != -1) {
      display.println(currentText.substring(0, colonIndex + 1)); 
      display.println(currentText.substring(colonIndex + 1));    
    } else {
      display.println(currentText); 
    }
    
    display.display();
    
    if (millis() - messageStartTime >= 2500) {
      currentState = IDLE;
      digitalWrite(MSG_PIN, LOW);
      digitalWrite(CALL_PIN, LOW);
    }
  }
  else if (currentState == CALL) {
    display.clearDisplay();
    display.setCursor(0, 0);
    display.println("Incoming call from:");
    display.println();
    display.println(currentText);
    display.display();
    
    if (millis() - callStartTime >= 10000) {
      currentState = IDLE;
      digitalWrite(CALL_PIN, LOW);
      digitalWrite(MSG_PIN, LOW);
    }
  }
  
  delay(10);
  }