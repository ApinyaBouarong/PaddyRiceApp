#include <WiFi.h>
#include <PubSubClient.h>
#include <Max6675.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <time.h>
#include <sys/time.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// WiFi credentials
const char *ssid = "!";
const char *password = "!!!!!!!!";
const char *ip_address = "192.168.33.87";
// MQTT Broker details
const char *mqtt_server = ip_address;
const char *mqtt_topic_pub = "sensor/data";  // Topic สำหรับ publish
const char *mqtt_topic_sub = "sensor/ai";    // Topic สำหรับ subscribe
const int port = 1883;

const char *server = ip_address;
const int server_port = 3030; // เพิ่ม port สำหรับ HTTP server
const char *api_endpoint = "/devices/1/target-values"; // Endpoint สำหรับ API

// MAX6675 setup
#define MAX6675_CLK1 33
#define MAX6675_CS1 25
#define MAX6675_DO1 26
Max6675 thermocouple1(MAX6675_CLK1, MAX6675_CS1, MAX6675_DO1);

#define MAX6675_CLK2 21
#define MAX6675_CS2 22
#define MAX6675_DO2 23
Max6675 thermocouple2(MAX6675_CLK2, MAX6675_CS2, MAX6675_DO2);

#define data_pin 39
int moistureValue = 0;

// LCD setup
#define I2C_SDA 18
#define I2C_SCL 19
LiquidCrystal_I2C lcd(0x27, 20, 4);

// WiFi and MQTT clients
WiFiClient espClient;
PubSubClient client(espClient);

// ตัวแปรสำหรับคำนวณค่าเฉลี่ย
#define SAMPLES_COUNT 5    // จำนวนตัวอย่างที่จะใช้คำนวณค่าเฉลี่ย

// อาร์เรย์สำหรับเก็บค่าตัวอย่าง
double temp_front_samples[SAMPLES_COUNT];
double temp_back_samples[SAMPLES_COUNT];
// double moisture_samples[SAMPLES_COUNT]; // Removed moisture_samples

// ตัวแปรสำหรับเก็บดัชนีปัจจุบันในอาร์เรย์
int sample_index = 0;
bool buffer_filled = false;

// ตัวแปรสำหรับเก็บค่า Target จาก API และ MQTT
double targetFrontTemp = 0.0;
double targetBackTemp = 0.0;
double targetHumidity = 0.0;
float currentHumidity = 0.0; // ตัวแปรสำหรับเก็บค่าความชื้นจาก MQTT, changed to float

// กำหนดขาสำหรับรีเลย์
#define RELAY_HUMIDITY 2      // เปลี่ยนเป็นขา GPIO ที่คุณใช้ควบคุมรีเลย์ (อาจไม่ได้ใช้แล้ว)
#define RELAY_TEMPFRONT 4
#define RELAY_TEMPBACK 16

unsigned long previousAPITime = 0; // ตัวแปรสำหรับเก็บเวลาที่ส่ง API ครั้งล่าสุด
const long apiInterval = 3000;      // ส่ง API ทุก 3 วินาที (3000 milliseconds)

// ฟังก์ชันสำหรับรับข้อความ MQTT
void callback(char *topic, byte *payload, unsigned int length) {
  Serial.print("Message arrived in topic: ");
  Serial.println(topic);
  Serial.print("Message:");
  for (int i = 0; i < length; i++) {
    Serial.print((char)payload[i]);
  }
  Serial.println();

  // ตรวจสอบว่าเป็นข้อความจากหัวข้อ sensor/ai หรือไม่
  if (strcmp(topic, mqtt_topic_sub) == 0) {
    Serial.println("Received data on sensor/ai topic"); // ADD THIS LINE
    StaticJsonDocument<100> doc;
    DeserializationError error = deserializeJson(doc, payload, length); // ใช้ doc เป็น destination
    serializeJsonPretty(doc, Serial);
    if (!error) {
      Serial.println("JSON parsed successfully");
      if (doc.containsKey("humidity")) {
        currentHumidity = doc["humidity"].as<float>();
        Serial.print("MQTT Humidity: ");
        Serial.println(currentHumidity);
      } else {
        Serial.println("JSON does not contain 'humidity' key"); 
      }
    } else {
      Serial.print("MQTT JSON parsing failed for humidity: ");
      Serial.println(error.c_str());
    }
  }
}

// ฟังก์ชันสำหรับดึงค่า Target จาก API
void fetchTargetValues() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    String serverPath =
        String("http://") + server + ":" + String(server_port) + api_endpoint; // ใช้ api_endpoint

    http.begin(espClient, serverPath.c_str());

    int httpResponseCode = http.GET();

    if (httpResponseCode > 0) {
      Serial.print("HTTP Response code (API): ");
      Serial.println(httpResponseCode);
      if (httpResponseCode == HTTP_CODE_OK) {
        String payload = http.getString();
        Serial.println("Target Values from API:");
        Serial.println(payload);

        StaticJsonDocument<200> doc;

        DeserializationError error = deserializeJson(doc, payload.c_str()); 
        if (!error) {
          if (doc.containsKey("target_front_temp")) {
            targetFrontTemp = doc["target_front_temp"].as<double>();
            Serial.print("API Target Front Temp: ");
            Serial.println(targetFrontTemp);
          }
          if (doc.containsKey("target_back_temp")) {
            targetBackTemp = doc["target_back_temp"].as<double>();
            Serial.print("API Target Back Temp: ");
            Serial.println(targetBackTemp);
          }
          if (doc.containsKey("target_humidity")) {
            targetHumidity = doc["target_humidity"].as<double>();
            Serial.print("API Target Humidity: ");
            Serial.println(targetHumidity);
          }
        } else {
          Serial.print("API JSON parsing failed: ");
          Serial.println(error.c_str());
        }
      }
    } else {
      Serial.print("Error on HTTP request (API): ");
      Serial.println(http.errorToString(httpResponseCode).c_str());
    }
    http.end();
  } else {
    Serial.println("WiFi not connected, cannot fetch target values from API.");
  }
}

// ฟังก์ชันสำหรับส่งค่า Target ไปยัง API
void sendTargetValues() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    String serverPath = String("http://") + server + ":" + String(server_port) + api_endpoint;

    http.begin(espClient, serverPath.c_str());
    http.addHeader("Content-Type", "application/json");

    // สร้าง JSON payload
    StaticJsonDocument<128> doc;
    doc["target_front_temp"] = targetFrontTemp;
    doc["target_back_temp"] = targetBackTemp;
    doc["target_humidity"] = targetHumidity;

    String payload;
    serializeJson(doc, payload);

    int httpResponseCode = http.POST(payload);
    if (httpResponseCode > 0) {
      Serial.print("HTTP Response code (Send API): ");
      Serial.println(httpResponseCode);
      if (httpResponseCode == HTTP_CODE_OK) {
        Serial.println("Target values sent to API successfully.");
      } else {
        Serial.println("Failed to send target values to API");
      }
    } else {
      Serial.print("Error on HTTP request (Send API): ");
      Serial.println(http.errorToString(httpResponseCode).c_str());
    }
    http.end();
  } else {
    Serial.println("WiFi not connected, cannot send target values to API.");
  }
}

void setup() {
  Serial.begin(115200);

  pinMode(data_pin, INPUT);

  // Initialize LCD
  Wire.begin(I2C_SDA, I2C_SCL);
  lcd.begin();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Connecting WiFi...");

  // Initialize WiFi
  setup_wifi();

  // Setup MQTT
  client.setServer(mqtt_server, port);
  client.setCallback(callback);

  // Initialize time via NTP
  configTime(0, 0, "pool.ntp.org");
  Serial.println("Waiting for time sync");
  while (!time(nullptr)) {
    delay(1000);
    Serial.print(".");
  }
  Serial.println("\nTime synced");

  // เคลียร์อาร์เรย์ตัวอย่าง
  for (int i = 0; i < SAMPLES_COUNT; i++) {
    temp_front_samples[i] = 0;
    temp_back_samples[i] = 0;
    // moisture_samples[i] = 0; // Removed
  }

  // ตั้งค่าขา Relay เป็น OUTPUT
  pinMode(RELAY_HUMIDITY, OUTPUT);
  digitalWrite(RELAY_HUMIDITY, LOW);
  pinMode(RELAY_TEMPFRONT, OUTPUT);
  digitalWrite(RELAY_TEMPFRONT, HIGH); // เริ่มต้น OFF
  pinMode(RELAY_TEMPBACK, OUTPUT);
  digitalWrite(RELAY_TEMPBACK, HIGH);  // เริ่มต้น OFF

  // ดึงค่า Target เริ่มต้น
  fetchTargetValues();

  // สมัครสมาชิกหัวข้อ MQTT ที่ต้องการรับค่าความชื้น
  if (client.connect("ESP32Client" /*, mqtt_username, mqtt_password */)) {
    Serial.println("Connected to MQTT Broker");
    client.subscribe(mqtt_topic_sub);
    Serial.print("Subscribed to topic: ");
    Serial.println(mqtt_topic_sub);
  } else {
    Serial.println("Failed to connect to MQTT broker");
  }
}

void loop() {
  if (!client.connected()) {
    reconnect_mqtt();
  }
  client.loop();

  // อ่านค่าจากเซนเซอร์
  double current_temp_front = thermocouple1.getCelsius();
  double current_temp_back = thermocouple2.getCelsius();
  int current_moisture_analog = map(analogRead(data_pin), 4095, 0, 0, 100);

  // เพิ่มค่าปัจจุบันลงในบัฟเฟอร์
  temp_front_samples[sample_index] = current_temp_front;
  temp_back_samples[sample_index] = current_temp_back;
  // moisture_samples[i] = current_moisture_analog; // Removed

  // อัปเดตดัชนีและตรวจสอบว่าบัฟเฟอร์เต็มหรือไม่
  sample_index = (sample_index + 1) % SAMPLES_COUNT;
  if (sample_index == 0) {
    buffer_filled = true;
  }

  // คำนวณค่าเฉลี่ย
  double temp_front = 0;
  double temp_back = 0;

  int actual_samples = buffer_filled ? SAMPLES_COUNT : sample_index;

  for (int i = 0; i < actual_samples; i++) {
    temp_front += temp_front_samples[i];
    temp_back += temp_back_samples[i];
  }

  if (actual_samples > 0) {
    temp_front /= actual_samples;
    temp_back /= actual_samples;
  }

  Serial.println("--- Sensor Readings ---");
  Serial.printf("Front Temp: %.2f C (Avg of %d samples) Target: %.2f C\n",
                 temp_front, actual_samples, targetFrontTemp);
  Serial.printf("Rear Temp: %.2f C (Avg of %d samples) Target: %.2f C\n",
                 temp_back, actual_samples, targetBackTemp);
  Serial.printf("Moisture (MQTT): %.2f %%\n", currentHumidity);

  // Control relays
  Serial.println("--- Relay Control ---");
  Serial.print("Front Relay Status: ");
  Serial.println(digitalRead(RELAY_TEMPFRONT));
  Serial.print("Rear Relay Status: ");
  Serial.println(digitalRead(RELAY_TEMPBACK));
  Serial.print("Humidity Relay Status: ");
  Serial.println(digitalRead(RELAY_HUMIDITY));

  if (temp_front > targetFrontTemp) {
    digitalWrite(RELAY_TEMPFRONT, LOW); // Active LOW
    Serial.println("Front Temp exceeded target, Front Relay ON");
    Serial.printf("Front Temp (%.2f C) is ABOVE target (%.2f C)\n", temp_front,
                   targetFrontTemp);
  } else {
    digitalWrite(RELAY_TEMPFRONT, HIGH); // Active LOW
    Serial.println("Front Temp within target, Front Relay OFF");
    Serial.printf("Front Temp (%.2f C) is WITHIN target (%.2f C)\n", temp_front,
                   targetFrontTemp);
  }

  if (temp_back > targetBackTemp) {
    digitalWrite(RELAY_TEMPBACK, LOW); // Active LOW
    Serial.println("Rear Temp exceeded target, Back Relay ON");
    Serial.printf("Rear Temp (%.2f C) is ABOVE target (%.2f C)\n", temp_back,
                   targetBackTemp);
  } else {
    digitalWrite(RELAY_TEMPBACK, HIGH); // Active LOW
    Serial.println("Rear Temp within target, Back Relay OFF");
    Serial.printf("Rear Temp (%.2f C) is WITHIN target (%.2f C)\n", temp_back,
                   targetBackTemp);
  }

  if (currentHumidity > targetHumidity) {
    digitalWrite(RELAY_HUMIDITY, HIGH);
    Serial.println("Humidity exceeded target, Humidity Relay ON");
    Serial.printf("Humidity (MQTT: %.2f %%) is ABOVE target (%.2f %%)\n",
                   currentHumidity, targetHumidity);
  } else {
    digitalWrite(RELAY_HUMIDITY, LOW);
    Serial.println("Humidity within target, Humidity Relay OFF");
    Serial.printf("Humidity (MQTT: %.2f %%) is WITHIN target (%.2f %%)\n",
                   currentHumidity, targetHumidity);
  }

  // Get timestamp
  time_t now;
  struct tm timeinfo;
  char timeStr[30];
  time(&now);
  localtime_r(&now, &timeinfo);
  strftime(timeStr, sizeof(timeStr), "%Y-%m-%dT%H:%M:%SZ", &timeinfo);

  // Display on LCD
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("F: ");
  lcd.print(temp_front);
  lcd.print("C (T:");
  lcd.print(targetFrontTemp);
  lcd.print(")");
  lcd.setCursor(0, 1);
  lcd.print("B: ");
  lcd.print(temp_back);
  lcd.print("C (T:");
  lcd.print(targetBackTemp);
  lcd.print(")");
  lcd.setCursor(0, 2);
  lcd.print("M: ");
  lcd.print(currentHumidity);
  lcd.print("% (T:");
  lcd.print(targetHumidity);
  lcd.print("%)");

  // Create JSON payload
  char payload[300];
  snprintf(payload, sizeof(payload),
           "{\"device_id\":1,\"timestamp\":\"%s\",\"front_temp\":%.2f,\"back_temp\":%.2f}",
           timeStr, temp_front, temp_back);

  client.publish(mqtt_topic_pub, payload);
  Serial.println("Data sent to MQTT (sensor/data): ");
  Serial.println(payload);

  delay(2000);

  if (millis() % 500 == 0) {
    fetchTargetValues();
  }

  // Send target values to API every 3 seconds
  if (millis() - previousAPITime >= apiInterval) {
    sendTargetValues();
    previousAPITime = millis();
  }
}

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("WiFi Connected");
  lcd.setCursor(0, 1);
  lcd.print("IP: ");
  lcd.print(WiFi.localIP());
}

void reconnect_mqtt() {
  Serial.println("Connect mqtt");
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    if (client.connect("ESP32Client" /*, mqtt_username, mqtt_password */)) {
      Serial.println("Connected to MQTT Broker");
      client.subscribe(mqtt_topic_sub);
      Serial.print("Subscribed to topic: ");
      Serial.println(mqtt_topic_sub);
    } else {
      Serial.print("Failed to connect to MQTT broker, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

