#include <Wire.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArtronShop_SHT45.h>
#include <time.h>
#include "esp_task_wdt.h"
#include <LiquidCrystal_I2C.h>

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
TwoWire I2C_back  = TwoWire(1);
ArtronShop_SHT45 sht45_front(&I2C_front, 0x44);
ArtronShop_SHT45 sht45_back(&I2C_back, 0x44);

// ----------------- LCD Config -----------------
#define LCD_SDA 25
#define LCD_SCL 26
#define LCD_I2C_ADDRESS 0x27

TwoWire I2C_lcd = TwoWire(2);
LiquidCrystal_I2C lcd(LCD_I2C_ADDRESS, 20, 4);

// ----------------- MQTT -----------------
WiFiClient espClient;
PubSubClient client(espClient);

// ----------------- Watchdog -----------------
#define WDT_TIMEOUT_SEC 8

void setupWatchdog() {
  esp_task_wdt_config_t config = {
    .timeout_ms = WDT_TIMEOUT_SEC * 1000,
    .idle_core_mask = (1 << portNUM_PROCESSORS) - 1,
    .trigger_panic = true
  };
  esp_task_wdt_init(&config);
  esp_task_wdt_add(NULL);
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
  Serial.print("Connecting to WiFi...");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected. IP: " + WiFi.localIP().toString());
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

void setupTime() {
  setenv("TZ", "ICT-7", 1); // ICT = UTC+7
  tzset();
  configTime(0, 0, "pool.ntp.org", "time.nist.gov");
  Serial.print("Waiting for NTP time");
  while (time(nullptr) < 100000) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\nTime initialized.");
}

unsigned long getCurrentTimestamp() {
  time_t now;
  time(&now);
  return now;
}

String getTimeStringFromTimestamp(time_t rawTime) {
  struct tm * timeinfo = localtime(&rawTime);
  char buffer[30];
  strftime(buffer, sizeof(buffer), "%d/%m/%Y %H:%M:%S", timeinfo);
  return String(buffer);
}

// ----------------- Setup -----------------
void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("\n--- Starting SHT45 + MQTT + LCD ---");

  connectWiFi();
  setupTime();
  setupWatchdog();
  client.setServer(mqtt_server, mqtt_port);

  I2C_front.begin(FRONT_SDA, FRONT_SCL, 400000);
  I2C_back.begin(BACK_SDA, BACK_SCL, 400000);
  I2C_lcd.begin(LCD_SDA, LCD_SCL, 400000); // เริ่ม I2C บัสจอ LCD

  if (!sht45_front.begin()) Serial.println("ERROR: Front sensor not found");
  else Serial.println("Front sensor OK");

  if (!sht45_back.begin()) Serial.println("ERROR: Back sensor not found");
  else Serial.println("Back sensor OK");

  lcd.begin();          // จอขนาด 20x4
  lcd.setBacklight(HIGH);    // เปิด backlight
  lcd.setCursor(0, 0);
  lcd.print("SHT45 Sensor Ready");

  Serial.println("--- Setup Complete ---\n");
}

// ----------------- Loop -----------------
void loop() {
  esp_task_wdt_reset();
  if (!client.connected()) reconnectMQTT();
  client.loop();

  float tf = 0, rhf = 0;
  float tb = 0, rhb = 0;

  bool frontOK = measureWithRetry(sht45_front, tf, rhf);
  bool backOK  = measureWithRetry(sht45_back, tb, rhb);

  Serial.println("=== Sensor Readings ===");

  if (frontOK) {
    Serial.print("Front Temp: "); Serial.print(tf); Serial.print(" C, ");
    Serial.print("Humidity: "); Serial.print(rhf); Serial.println(" %");
  } else Serial.println("Failed to read front sensor");

  if (backOK) {
    Serial.print("Back Temp : "); Serial.print(tb); Serial.print(" C, ");
    Serial.print("Humidity: "); Serial.print(rhb); Serial.println(" %");
  } else Serial.println("Failed to read back sensor");

  if (frontOK && backOK) {
    unsigned long timestamp = getCurrentTimestamp();
    String timeThai = getTimeStringFromTimestamp(timestamp);

    char payload[300];
    snprintf(payload, sizeof(payload),
             "{\"timestamp\":%lu,\"front_temp\":%.2f,\"front_humidity\":%.2f,\"back_temp\":%.2f,\"back_humidity\":%.2f,\"time_thai\":\"%s\"}",
             timestamp, tf, rhf, tb, rhb, timeThai.c_str());
    client.publish(mqtt_topic, payload);
    Serial.print("MQTT Sent: ");
    Serial.println(payload);

    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Time:");
    lcd.setCursor(6, 0);
    lcd.print(timeThai.substring(11)); // HH:MM:SS

    lcd.setCursor(0, 1);
    lcd.printf("F T: %.1fC H: %.1f%%", tf, rhf);

    lcd.setCursor(0, 2);
    lcd.printf("B T: %.1fC H: %.1f%%", tb, rhb);
  }

  Serial.println("========================\n");
  delay(2000);
}
