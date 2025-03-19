#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <Max6675.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// WiFi credentials
const char* ssid = "DESKTOP-PADDY";
const char* password = "36#96T4p";

// MQTT Broker details
const char* mqtt_server = "192.168.137.91";
const char* mqtt_topic = "sensor/data";
const int port = 1883;


// DHT22 setup
#define DHTPIN 32
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

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
int moistureValue =0;
// LCD setup
#define I2C_SDA 18
#define I2C_SCL 19
LiquidCrystal_I2C lcd(0x27, 20, 4); // Address 0x27, 20x4 LCD

// WiFi and MQTT clients
WiFiClient espClient;
PubSubClient client(espClient);

void setup() {
  Serial.begin(115200);

  pinMode(data_pin, INPUT);
  // Initialize DHT22
  dht.begin();

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
}

void loop() {
  if (!client.connected()) {
    reconnect_mqtt();
  }
  client.loop();

  double sum_temp_front = 0, sum_temp_back = 0;
  int sum_humidity = 0, sum_moisture = 0;

  Serial.println("Starting sensor readings...");
  
  for (int i = 0; i < 5; i++) {
    double temp_front = thermocouple1.getCelsius();
    double temp_back = thermocouple2.getCelsius();
    float humidity = dht.readHumidity();
    int moisture = map(analogRead(data_pin), 4095, 0, 0, 100);

    // Log individual readings
    Serial.printf("Reading %d:\n", i + 1);
    Serial.printf("  Front Temp: %.2f C\n", temp_front);
    Serial.printf("  Rear Temp: %.2f C\n", temp_back);
    Serial.printf("  Humidity: %.2f %%\n", humidity);
    Serial.printf("  Moisture: %d %%\n", moisture);

    if (!isnan(humidity)) {
      sum_humidity += humidity;
    }
    if (temp_front != NAN && temp_back != NAN) {
      sum_temp_front += temp_front;
      sum_temp_back += temp_back;
    }
    sum_moisture += moisture;

    delay(200);
  }

  // Calculate averages
  double avg_temp_front = sum_temp_front / 5;
  double avg_temp_back = sum_temp_back / 5;
  int avg_humidity = sum_humidity / 5;
  int avg_moisture = sum_moisture / 5;

  Serial.println("Finished collecting sensor data.");
  Serial.printf("Averages:\n");
  Serial.printf("  Avg Front Temp: %.2f C\n", avg_temp_front);
  Serial.printf("  Avg Rear Temp: %.2f C\n", avg_temp_back);
  Serial.printf("  Avg Humidity: %d %%\n", avg_humidity);
  Serial.printf("  Avg Moisture: %d %%\n", avg_moisture);

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
  lcd.print("TempFront: ");
  lcd.print(avg_temp_front);
  lcd.print(" C");
  lcd.setCursor(0, 1);
  lcd.print("TempBack: ");
  lcd.print(avg_temp_back);
  lcd.print(" C");
  lcd.setCursor(0, 2);
  lcd.print("Humidity: ");
  lcd.print(avg_humidity);
  lcd.print(" %");
  lcd.setCursor(0, 3);
  lcd.print("Moisture: ");
  lcd.print(avg_moisture);
  lcd.print(" %");

  // Create JSON payload
  char payload[300];
  snprintf(payload, sizeof(payload),
           "{\"device_id\":1,\"timestamp\":\"%s\",\"front_temperature\":%.2f,\"rear_temperature\":%.2f,\"moisture\":%d,\"status\":1}",
           timeStr, avg_temp_front, avg_temp_back, avg_moisture);

  // Publish to MQTT Broker
  client.publish(mqtt_topic, payload);
  Serial.println("Data sent to MQTT: ");
  Serial.println(payload);

  delay(10000); // Wait for 10 seconds before the next loop
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
  // Loop until we're reconnected
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    // Attempt to connect
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
