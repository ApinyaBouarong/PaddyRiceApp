#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <Max6675.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <time.h>
#include <HTTPClient.h>

const char* ssid = "DESKTOP-PADDY";
const char* password = "36#96T4p";
const char* mqtt_server = "192.168.137.28";
const char* mqtt_topic = "sensor/data";
const int port = 1883;

String device_id = "1";
const int device_ID = 1;

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

struct SensorData{
  float frontTemp;
  float rearTemp;
  float moisture;
};

struct Config{
  int delaySensor;
  int delayPushData;
};

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

  configTime(7 * 3600, 0, "pool.ntp.org", "time.nist.gov"); // UTC+7 สำหรับไทย
  Serial.println("Syncing time...");
  while (!time(nullptr)) {
    delay(1000);
    Serial.print(".");
  }
  Serial.println("\nTime synced successfully.");

  // Initialize WiFi
  // setup_wifi();

  // Setup MQTT
  // client.setServer(mqtt_server, port);
}

void loop() {
  // if (!client.connected()) {
  //   reconnect_mqtt();
  // }
  // client.loop();
  SensorData sensor;
  Config config;
  config.delaySensor = 200;
  config.delayPushData = 5000;
  String formattedTime;

  Serial.println("Starting sensor readings...");
  getdatasensor(config,sensor);
  getFormattedTime(formattedTime);

  Serial.printf("  Front Temp: %.2f C\n", sensor.frontTemp);
  Serial.printf("  Rear Temp:  %.2f C\n", sensor.rearTemp);
  Serial.printf("  Moisture:   %.2f %%\n", sensor.moisture);
  Serial.printf("  TimeStamp:  ");
  Serial.println(formattedTime);

  updateLCD(sensor.frontTemp, sensor.rearTemp, sensor.moisture);

  // sendToMQTT(mqtt_topic, device_ID, formattedTime.c_str(), sensor.frontTemp, sensor.rearTemp, sensor.moisture);

  // fetchDataFromAPI();

  delay(7000);
}

void getdatasensor(Config config,SensorData &sensor){
  int num = config.delayPushData / config.delaySensor;
  double sum_temp_front = 0, sum_temp_back = 0;
  int sum_moisture = 0;

  for (int i = 0; i < num; i++) {
    double temp_front = thermocouple1.getCelsius();
    double temp_back = thermocouple2.getCelsius();
    int moisture = map(analogRead(data_pin), 4095, 0, 0, 100);

    // Serial.printf("Reading %d:\n", i + 1);
    // Serial.printf("  Front Temp: %.2f C\n", temp_front);
    // Serial.printf("  Rear Temp: %.2f C\n", temp_back);
    // Serial.printf("  Moisture: %d %%\n", moisture);

    if (temp_front != NAN && temp_back != NAN) {
      sum_temp_front += temp_front;
      sum_temp_back += temp_back;
    }
    sum_moisture += moisture;
    delay(config.delaySensor);
  }

  // Calculate averages
  sensor.frontTemp = sum_temp_front / num;
  sensor.rearTemp = sum_temp_back / num;
  sensor.moisture = sum_moisture / num;
  // return sensor;
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

void fetchDataFromAPI() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;

    // URL ของ API
    String serverPath = "http://192.168.12.87:3000/api/data?device_id=" + device_id;
    Serial.println("Requesting: " + serverPath);

    http.begin(serverPath.c_str());
    int httpResponseCode = http.GET();

    if (httpResponseCode > 0) {
      String response = http.getString();
      Serial.println("Received data from API:");
      Serial.println(response);

      // แปลง JSON เป็นข้อมูลที่ใช้งานได้ (ถ้าต้องการ)
      // ตัวอย่างการ Parse JSON สามารถใช้ ArduinoJson ไลบรารี

    } else {
      Serial.print("Error code: ");
      Serial.println(httpResponseCode);
    }

    http.end(); // ปิดการเชื่อมต่อ
  } else {
    Serial.println("WiFi Disconnected");
  }
}

void getFormattedTime(String &formattedTime) {
  time_t now = time(nullptr);
  struct tm timeinfo;
  char timeStr[30];

  if (localtime_r(&now, &timeinfo)) {
    strftime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S", &timeinfo);
    formattedTime = timeStr;
  } else {
    formattedTime = "N/A";
  }
}

void updateLCD(float frontTemp, float rearTemp, float moisture) {
  lcd.clear(); // ล้างจอ
  lcd.setCursor(0, 0);
  lcd.print("TempFront: ");
  lcd.print(frontTemp, 2); // แสดงค่า frontTemp (2 ตำแหน่งทศนิยม)
  lcd.print(" C");

  lcd.setCursor(0, 1);
  lcd.print("TempBack: ");
  lcd.print(rearTemp, 2); // แสดงค่า rearTemp (2 ตำแหน่งทศนิยม)
  lcd.print(" C");

  lcd.setCursor(0, 2);
  lcd.print("Moisture: ");
  lcd.print(moisture, 2); // แสดงค่า moisture (2 ตำแหน่งทศนิยม)
  lcd.print(" %");
}

void sendToMQTT(const char* topic, int deviceId, const char* timestamp, float frontTemp, float rearTemp, float moisture) {
  char payload[300]; // ตัวแปรสำหรับเก็บ JSON payload
  snprintf(payload, sizeof(payload),
           "{\"device_id\":\"%d\",\"timestamp\":\"%s\",\"front_temperature\":%.2f,\"rear_temperature\":%.2f,\"moisture\":%.2f}",
           deviceId, timestamp, frontTemp, rearTemp, moisture);

  // ส่งข้อมูลไปยัง MQTT Broker
  if (client.publish(topic, payload)) {
    Serial.println("Data sent to MQTT:");
    Serial.println(payload);
  } else {
    Serial.println("Failed to send data to MQTT");
  }
}

