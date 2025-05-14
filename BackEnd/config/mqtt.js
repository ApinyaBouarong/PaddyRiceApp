const mqtt = require("mqtt");
const pool = require("./db");
const admin = require("./firebase");
const { wss } = require("../app");

const mqttHost = "mqtt://192.168.33.87";
const mqttPort = 1883;
const sensorDataTopic = "sensor/data";

const clientMqtt = mqtt.connect(mqttHost, {
  port: mqttPort,
  clientId: "NodeJSClient",
  clean: true,
});

const alertCooldownMap = new Map();
const ALERT_COOLDOWN_MS = 10 * 60 * 1000;
const sensorDataCache = new Map();

clientMqtt.on("connect", () => {
  clientMqtt.subscribe([sensorDataTopic], (err) => {
    if (err) console.error("Failed to subscribe:", err);
  });
});

clientMqtt.on("message", async (topic, message) => {
  try {
    const parsedMessage = JSON.parse(message.toString());

    if (topic === sensorDataTopic) {
      console.log("sensor/data");
      const {
        deviceId,
        front_temp: currentFrontTemp,
        back_temp: currentBackTemp,
        humidity,
        timestamp: timestamp,
      } = parsedMessage;

      console.log("DATA:", parsedMessage);
      if (deviceId) {
        const existing = sensorDataCache.get(deviceId) || {};
        sensorDataCache.set(deviceId, {
          ...existing,
          front_temp: currentFrontTemp,
          back_temp: currentBackTemp,
          humidity,
          timestamp: timestamp,
        });

        await checkAndSaveSensorData(deviceId);
      }
    }
  } catch (error) {
    console.error("Error parsing message:", error);
  }
});

async function checkAndSaveSensorData(deviceId) {
  const data = sensorDataCache.get(deviceId);

  if (
    data &&
    data.front_temp !== undefined &&
    data.back_temp !== undefined &&
    data.humidity !== undefined &&
    data.timestamp
  ) {
    try {
      await pool.query(
        `INSERT INTO device_readings (device_id, front_temp, back_temp, humidity, time_stamp)
        VALUES (?, ?, ?, ?, ?)`,
        [
          deviceId,
          data.front_temp,
          data.back_temp,
          data.humidity,
          data.timestamp,
        ]
      );
      console.log(`✅ Sensor data saved for device ${deviceId}`);
      sensorDataCache.delete(deviceId);

      // ตรวจสอบเป้าหมายจาก DB
      const [devices] = await pool.query(
        "SELECT target_front_temp, target_back_temp, target_humidity, user_id, device_name FROM devices WHERE device_id = ?",
        [deviceId]
      );
      console.log("TAGET:", devices);

      if (devices.length === 0) return;

      const device = devices[0];
      const targetFrontTemp = device.target_front_temp;
      const targetBackTemp = device.target_back_temp;
      const targetHumidity = device.target_humidity;
      const userId = device.user_id;
      let deviceName = device.device_name || "Device";

      if (deviceName.length > 15) {
        deviceName = deviceName.substring(0, 15) + "...";
      }

      const now = Date.now();
      const notificationsToSend = [];

      // ฟังก์ชันตรวจสอบการแจ้งเตือน
      function shouldSendNotification(deviceId, type, currentValue) {
        const key = `${deviceId}-${type}`;
        const lastSent = alertCooldownMap.get(key) || {
          lastSentTime: 0,
          lastValue: null,
        };

        // ตรวจสอบว่าเป็นการเปลี่ยนแปลงค่าจริง ๆ และดูว่าเวลาผ่านไป 10 นาทีแล้วหรือไม่
        if (
          currentValue !== lastSent.lastValue ||
          now - lastSent.lastSentTime >= ALERT_COOLDOWN_MS
        ) {
          alertCooldownMap.set(key, {
            lastSentTime: now,
            lastValue: currentValue,
          });
          return true; // ส่งการแจ้งเตือน
        }

        return false; // ไม่ส่งการแจ้งเตือน
      }

      // FRONT TEMP ALERT
      console.log(
        "deviceId: %d, FrontTemp > TargetFrontTemp: %f > %f",
        deviceId,
        data.front_temp,
        targetFrontTemp
      );
      if (
        data.front_temp > targetFrontTemp &&
        shouldSendNotification(deviceId, "front_temp", data.front_temp)
      ) {
        notificationsToSend.push({
          type: "front_temp",
          current_value: data.front_temp,
          target_value: targetFrontTemp,
          title: {
            en: `Alert! Front Temp Exceeded Target (${deviceName})`,
            th: `แจ้งเตือน! อุณหภูมิด้านหน้าเกินเป้าหมาย (${deviceName})`,
          },
          body: {
            en: `Front Temperature (${data.front_temp}°C) exceeds target (${targetFrontTemp}°C)`,
            th: `อุณหภูมิด้านหน้า (${data.front_temp}°C) สูงกว่าเป้าหมาย (${targetFrontTemp}°C)`,
          },
        });
      }

      // BACK TEMP ALERT
      console.log(
        "deviceId: %d ,BackTemp > TargetBackTemp: %f > %f",
        deviceId,
        data.back_temp,
        targetBackTemp
      );
      if (
        data.back_temp > targetBackTemp &&
        shouldSendNotification(deviceId, "back_temp", data.back_temp)
      ) {
        notificationsToSend.push({
          type: "back_temp",
          current_value: data.back_temp,
          target_value: targetBackTemp,
          title: {
            en: `Alert! Back Temp Exceeded Target (${deviceName})`,
            th: `แจ้งเตือน! อุณหภูมิด้านหลังเกินเป้าหมาย (${deviceName})`,
          },
          body: {
            en: `Back Temperature (${data.back_temp}°C) exceeds target (${targetBackTemp}°C)`,
            th: `อุณหภูมิด้านหลัง (${data.back_temp}°C) สูงกว่าเป้าหมาย (${targetBackTemp}°C)`,
          },
        });
      }

      // HUMIDITY ALERT
      console.log(
        "deviceId: %d ,Humidity < TargetHumidity: %f < %f",
        deviceId,
        data.humidity,
        targetHumidity
      );
      if (
        data.humidity - 3 < targetHumidity &&
        shouldSendNotification(deviceId, "humidity", data.humidity - 3)
      ) {
        notificationsToSend.push({
          type: "humidity",
          current_value: data.humidity,
          target_value: targetHumidity,
          title: {
            en: `Alert! Humidity Below Target (${deviceName})`,
            th: `แจ้งเตือน! ความชื้นต่ำกว่าเป้าหมาย (${deviceName})`,
          },
          body: {
            en: `Humidity (${data.humidity}%) is below target (${targetHumidity}%)`,
            th: `ความชื้น (${data.humidity}%) ต่ำกว่าเป้าหมาย (${targetHumidity}%)`,
          },
        });
      }

      if (notificationsToSend.length > 0 && userId) {
        const [users] = await pool.query(
          "SELECT token, language FROM users WHERE user_id = ?",
          [userId]
        );

        if (users.length > 0) {
          const fcmToken = users[0].token;
          const preferredLanguage = users[0].language || "en";

          for (const notification of notificationsToSend) {
            const fcmPayload = {
              notification: {
                title:
                  notification.title[preferredLanguage] ||
                  notification.title.en,
                body:
                  notification.body[preferredLanguage] || notification.body.en,
              },
              data: {
                deviceId: String(deviceId),
                deviceName,
                type: notification.type,
                loc_title: JSON.stringify(notification.title),
                loc_body: JSON.stringify(notification.body),
              },
              token: fcmToken,
            };

            try {
              await admin.messaging().send(fcmPayload);
              console.log("✅ FCM notification sent.");
            } catch (err) {
              console.error("❌ Error sending FCM:", err);
            }

            try {
              await pool.query(
                "INSERT INTO notifications (device_id, sensor_type, current_value, target_value, timestamp) VALUES (?, ?, ?, ?, NOW())",
                [
                  deviceId,
                  notification.type,
                  notification.current_value,
                  notification.target_value,
                ]
              );
              console.log("✅ Notification stored in DB.");
            } catch (err) {
              console.error("❌ Error storing notification:", err);
            }

            if (wss) {
              wss.clients.forEach((client) => {
                if (client.userId === userId) {
                  client.send(
                    JSON.stringify({
                      type: "sensor_alert",
                      deviceId,
                      deviceName,
                      title:
                        notification.title[preferredLanguage] ||
                        notification.title.en,
                      body:
                        notification.body[preferredLanguage] ||
                        notification.body.en,
                      alertType: notification.type,
                    })
                  );
                }
              });
            }
          }
        }
      }
    } catch (error) {
      console.error("❌ Error in checkAndSaveSensorData:", error);
    }
  }
}

clientMqtt.on("error", (err) => {
  console.error("MQTT Error:", err);
});

module.exports = clientMqtt;
module.exports.mqttTopic = sensorDataTopic;
