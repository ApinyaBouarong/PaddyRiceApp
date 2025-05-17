#include <Wire.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArtronShop_SHT45.h>
#include <time.h>

// WiFi & MQTT Config
const char *ssid = "!";                  
const char *password = "!!!!!!!!";       
const char *mqtt_server = "192.168.0.103";
const int mqtt_port = 1883;
const char *mqtt_topic = "sensor/back";

#define BACK_SDA 18
#define BACK_SCL 19

TwoWire I2C_back = TwoWire(1);
ArtronShop_SHT45 sht45_back(&I2C_back, 0x44);

WiFiClient espClient;
PubSubClient client(espClient);

// ฟังก์ชันเชื่อมต่อ WiFi
void connectWiFi() {
  Serial.print("Connecting to WiFi...");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected. IP: " + WiFi.localIP().toString());
}

// ฟังก์ชันเชื่อมต่อ MQTT
void reconnectMQTT() {
  while (!client.connected()) {
    Serial.print("Connecting to MQTT...");
    if (client.connect("ESP32Back")) {
      Serial.println("connected");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

// อ่านค่า SHT45 พร้อม retry 3 ครั้ง
bool measureWithRetry(ArtronShop_SHT45 &sensor, float &temp, float &hum) {
  for (int i = 0; i < 3; i++) {
    if (sensor.measure()) {
      temp = sensor.temperature();
      hum = sensor.humidity();
      return true;
    }
    delay(50);
  }
  return false;
}

// ตั้งเวลาตามโซนเวลาไทย (UTC+7)
void setupTime() {
  configTime(7 * 3600, 0, "pool.ntp.org", "time.nist.gov");
  Serial.print("Waiting for NTP time");
  while (time(nullptr) < 100000) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\nTime initialized.");
}

// คืนค่าเวลาปัจจุบันในรูปแบบอ่านง่าย เช่น "2025-05-16 15:45:10"
String getFormattedTime() {
  time_t now;
  struct tm timeinfo;
  time(&now);
  localtime_r(&now, &timeinfo);
  char buf[25];
  strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M:%S", &timeinfo);
  return String(buf);
}

void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("Starting Back Sensor");

  connectWiFi();
  setupTime();
  client.setServer(mqtt_server, mqtt_port);

  I2C_back.begin(BACK_SDA, BACK_SCL);

  if (!sht45_back.begin()) {
    Serial.println("ERROR: Back sensor not found");
    while (1) delay(1000);
  } else {
    Serial.println("Back sensor OK");
  }
}

void loop() {
  if (!client.connected()) reconnectMQTT();
  client.loop();

  float temp = 0, hum = 0;
  bool ok = measureWithRetry(sht45_back, temp, hum);

  if (ok) {
    String timeStr = getFormattedTime();

    char payload[200];
    snprintf(payload, sizeof(payload),
             "{\"time\":\"%s\",\"back_temp\":%.2f,\"back_humidity\":%.2f}",
             timeStr.c_str(), temp, hum);

    client.publish(mqtt_topic, payload);
    Serial.print("MQTT Sent: ");
    Serial.println(payload);
  } else {
    Serial.println("Failed to read back sensor");
  }

  delay(2000);
}
