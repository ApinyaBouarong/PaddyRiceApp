#include <Wire.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArtronShop_SHT45.h>
#include <time.h>

// ----------------- WiFi & MQTT Config -----------------
const char *ssid = "!";
const char *password = "!!!!!!!!";
const char *mqtt_server = "192.168.33.87";
const int mqtt_port = 1883;
const char *mqtt_topic = "sensor/data";

// ----------------- SHT45 Sensor Config -----------------
#define FRONT_SDA 21
#define FRONT_SCL 22
#define BACK_SDA 18
#define BACK_SCL 19

TwoWire I2C_front = TwoWire(0);
TwoWire I2C_back = TwoWire(1);
ArtronShop_SHT45 sht45_front(&I2C_front, 0x44);
ArtronShop_SHT45 sht45_back(&I2C_back, 0x44);

// ----------------- MQTT -----------------
WiFiClient espClient;
PubSubClient client(espClient);

// ----------------- Time (NTP) -----------------
const char* ntpServer = "pool.ntp.org";
const long gmtOffset_sec = 7 * 3600;
const int daylightOffset_sec = 0;

// ----------------- Watchdog -----------------
hw_timer_t *watchdogTimer = NULL;
#define WDT_TIMEOUT_SEC 8  // รีเซ็ตหากค้างเกิน 8 วิ

void IRAM_ATTR resetModule() {
  esp_restart();
}

// ----------------- Functions -----------------
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

void connectWiFi() {
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  int retry = 0;
  while (WiFi.status() != WL_CONNECTED && retry < 20) {
    delay(500);
    Serial.print(".");
    retry++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi connected: " + WiFi.localIP().toString());
  } else {
    Serial.println("\nFailed to connect to WiFi, restarting...");
    delay(1000);
    ESP.restart();
  }
}

void reconnectMQTT() {
  while (!client.connected()) {
    Serial.print("Connecting to MQTT...");
    if (client.connect("ESP32Client")) {
      Serial.println("connected");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

unsigned long getUnixTime() {
  time_t now;
  time(&now);
  return now;
}

void setupWatchdog() {
  watchdogTimer = timerBegin(0, 80, true);              // 80 MHz / 80 = 1 MHz → 1 tick = 1us
  timerAttachInterrupt(watchdogTimer, &resetModule, true);
  timerAlarmWrite(watchdogTimer, WDT_TIMEOUT_SEC * 1000000, false); // in microseconds
  timerAlarmEnable(watchdogTimer);
}

// ----------------- Setup -----------------
void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("\n--- Starting SHT45 + MQTT + Watchdog ---");

  connectWiFi();
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
  client.setServer(mqtt_server, mqtt_port);

  I2C_front.begin(FRONT_SDA, FRONT_SCL);
  I2C_back.begin(BACK_SDA, BACK_SCL);

  if (!sht45_front.begin()) Serial.println("ERROR: Front sensor not found");
  else Serial.println("Front sensor OK");

  if (!sht45_back.begin()) Serial.println("ERROR: Back sensor not found");
  else Serial.println("Back sensor OK");

  setupWatchdog();

  Serial.println("--- Setup Complete ---\n");
}

// ----------------- Loop -----------------
void loop() {
  timerWrite(watchdogTimer, 0);  // รีเซ็ต watchdog ทุกครั้งที่ loop ไม่ค้าง

  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi lost. Reconnecting...");
    connectWiFi();
  }

  if (!client.connected()) reconnectMQTT();
  client.loop();

  float tf = 0, rhf = 0;
  float tb = 0, rhb = 0;

  bool frontOK = measureWithRetry(sht45_front, tf, rhf);
  bool backOK  = measureWithRetry(sht45_back, tb, rhb);

  if (frontOK && backOK) {
    unsigned long timestamp = getUnixTime();
    char payload[250];
    snprintf(payload, sizeof(payload),
             "{\"timestamp\":%lu,\"front_temp\":%.2f,\"front_humidity\":%.2f,\"back_temp\":%.2f,\"back_humidity\":%.2f}",
             timestamp, tf, rhf, tb, rhb);
    client.publish(mqtt_topic, payload);
    Serial.println("MQTT Sent: " + String(payload));
  } else {
    Serial.println("Sensor error: frontOK=" + String(frontOK) + " backOK=" + String(backOK));
  }

  delay(2000);
}
