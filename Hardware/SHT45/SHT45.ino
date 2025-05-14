#include <Wire.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArtronShop_SHT45.h>
#include <time.h> // Include library for time functions

// ----------------- WiFi & MQTT Config -----------------
const char *ssid = "!";
const char *password = "!!!!!!!!";
const char *mqtt_server = "192.168.33.87"; // เปลี่ยนเป็น IP ของ MQTT broker
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

// Function to get current timestamp in milliseconds
unsigned long getCurrentTimeMillis() {
  return millis();
}

// ----------------- Setup -----------------
void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("\n--- Starting SHT45 + MQTT with Timestamp ---");

  connectWiFi();
  client.setServer(mqtt_server, mqtt_port);

  I2C_front.begin(FRONT_SDA, FRONT_SCL);
  I2C_back.begin(BACK_SDA, BACK_SCL);

  if (!sht45_front.begin()) {
    Serial.println("ERROR: Front sensor not found");
  } else {
    Serial.println("Front sensor OK");
  }

  if (!sht45_back.begin()) {
    Serial.println("ERROR: Back sensor not found");
  } else {
    Serial.println("Back sensor OK");
  }

  Serial.println("--- Setup Complete ---\n");
}

// ----------------- Loop -----------------
void loop() {
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
  } else {
    Serial.println("Failed to read front sensor");
  }

  if (backOK) {
    Serial.print("Back Temp : "); Serial.print(tb); Serial.print(" C, ");
    Serial.print("Humidity: "); Serial.print(rhb); Serial.println(" %");
  } else {
    Serial.println("Failed to read back sensor");
  }

  if (frontOK && backOK) {
    unsigned long timestamp = getCurrentTimeMillis();
    char payload[250]; // Increased buffer size to accommodate timestamp
    snprintf(payload, sizeof(payload),
             "{\"timestamp\":%lu,\"front_temp\":%.2f,\"front_humidity\":%.2f,\"back_temp\":%.2f,\"back_humidity\":%.2f}",
             timestamp, tf, rhf, tb, rhb);
    client.publish(mqtt_topic, payload);
    Serial.print("MQTT Sent: ");
    Serial.println(payload);
  }

  Serial.println("========================\n");
  delay(2000);
}