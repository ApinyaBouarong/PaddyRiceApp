const mqtt = require("mqtt");
const pool = require("./db");
const admin = require("./firebase");
const { wss } = require("../app");

const mqttHost = "mqtt://192.168.33.87";
const mqttPort = 1883;
const sensorDataTopic = "sensor/data";
const sensorAiTopic = "sensor/ai"; // New topic for AI sensor data

const mqttUsername = "mymqtt";
const mqttPassword = "paddy";

const clientMqtt = mqtt.connect(mqttHost, {
  port: mqttPort,
  clientId: "NodeJSClient",
  clean: true,
  username: mqttUsername,
  password: mqttPassword,
});

const alertCooldownMap = new Map();
const ALERT_COOLDOWN_MS = 10 * 60 * 1000;

clientMqtt.on("connect", () => {
  // console.log('Connected to MQTT Broker');
  clientMqtt.subscribe([sensorDataTopic, sensorAiTopic], (err) => {
    // Subscribe to both topics
    if (err) {
      console.error(`Failed to subscribe to topics:`, err);
    }
    // else {
    //   console.log(`Subscribed to topics: ${sensorDataTopic}, ${sensorAiTopic}`);
    // }
  });
});

clientMqtt.on("message", async (topic, message) => {
  console.log(`Message received from topic ${topic}:`);
  try {
    const parsedMessage = JSON.parse(message.toString());
    console.log("Parsed Message:", parsedMessage);

    if (topic === sensorDataTopic) {
      const {
        device_id: deviceId,
        front_temp: currentFrontTemp,
        back_temp: currentBackTemp,
        humidity: currentHumidity,
      } = parsedMessage;

      if (deviceId) {
        try {
          const [devices] = await pool.query(
            "SELECT target_front_temp, target_back_temp, target_humidity, user_id FROM devices WHERE device_id = ?",
            [deviceId]
          );
          console.log("Devices:", devices);

          if (devices.length > 0) {
            const target = devices[0];
            const userId = target.user_id;
            const targetFrontTemp = target.target_front_temp;
            const targetBackTemp = target.target_back_temp;
            const targetHumidity = target.target_humidity;
            try {
              const [deviceRows] = await pool.query(
                "SELECT device_name FROM devices WHERE device_id = ?",
                [deviceId]
              );
              let deviceName = deviceRows[0]?.device_name || "Device";
              console.log("device name: ", deviceName);
              if (deviceName.length > 15) {
                deviceName = deviceName.substring(0, 15) + "...";
              }
              const notificationsToSend = [];

              const now = Date.now();

              function shouldSendNotification(deviceId, type) {
                const key = `${deviceId}-${type}`;
                const lastSent = alertCooldownMap.get(key) || 0;
                if (now - lastSent >= ALERT_COOLDOWN_MS) {
                  alertCooldownMap.set(key, now);
                  return true;
                }
                return false;
              }

              // FRONT TEMP
              if (currentFrontTemp > targetFrontTemp) {
                const type = "front_temp";
                if (shouldSendNotification(deviceId, type)) {
                  notificationsToSend.push({
                    title: {
                      en: `Alert! Front Temp Exceeded Target (${deviceName})`,
                      th: `แจ้งเตือน! อุณหภูมิด้านหน้าเกินเป้าหมาย (${deviceName})`,
                    },
                    body: {
                      en: `Front Temperature (${currentFrontTemp}°C) exceeds target (${targetFrontTemp}°C)`,
                      th: `อุณหภูมิด้านหน้า (${currentFrontTemp}°C) สูงกว่าเป้าหมาย (${targetFrontTemp}°C)`,
                    },
                    type,
                    current_value: currentFrontTemp,
                    target_value: targetFrontTemp,
                  });
                }
              }

              // BACK TEMP
              if (currentBackTemp > targetBackTemp) {
                const type = "back_temp";
                if (shouldSendNotification(deviceId, type)) {
                  notificationsToSend.push({
                    title: {
                      en: `Alert! Back Temp Exceeded Target (${deviceName})`,
                      th: `แจ้งเตือน! อุณหภูมิด้านหลังเกินเป้าหมาย (${deviceName})`,
                    },
                    body: {
                      en: `Back Temperature (${currentBackTemp}°C) exceeds target (${targetBackTemp}°C)`,
                      th: `อุณหภูมิด้านหลัง (${currentBackTemp}°C) สูงกว่าเป้าหมาย (${targetBackTemp}°C)`,
                    },
                    type,
                    current_value: currentBackTemp,
                    target_value: targetBackTemp,
                  });
                }
              }

              // HUMIDITY
              if (currentHumidity < targetHumidity - 3) {
                const type = "humidity";
                if (shouldSendNotification(deviceId, type)) {
                  notificationsToSend.push({
                    title: {
                      en: `Alert! Humidity Below Target (${deviceName})`,
                      th: `แจ้งเตือน! ความชื้นต่ำกว่าเป้าหมาย (${deviceName})`,
                    },
                    body: {
                      en: `Humidity (${currentHumidity}%) is below target (${targetHumidity}%)`,
                      th: `ความชื้น (${currentHumidity}%) ต่ำกว่าเป้าหมาย (${targetHumidity}%)`,
                    },
                    type,
                    current_value: currentHumidity,
                    target_value: targetHumidity,
                  });
                }
              }

              if (userId && notificationsToSend.length > 0) {
                try {
                  const [users] = await pool.query(
                    "SELECT token, language FROM users WHERE user_id = ?",
                    [userId]
                  );
                  console.log("User Data with Token and Language:", users);

                  if (users.length > 0 && users[0].token) {
                    const fcmToken = users[0].token;
                    const preferredLanguage = users[0].language || "en";

                    for (const notification of notificationsToSend) {
                      const fcmPayload = {
                        notification: {
                          title:
                            notification.title[preferredLanguage] ||
                            notification.title.en ||
                            "Alert!",
                          body:
                            notification.body[preferredLanguage] ||
                            notification.body.en ||
                            "Sensor Alert!",
                        },
                        data: {
                          deviceId: String(deviceId),
                          deviceName: String(deviceName),
                          type: notification.type,
                          loc_title: JSON.stringify(notification.title),
                          loc_body: JSON.stringify(notification.body),
                        },
                        token: fcmToken,
                      };
                      try {
                        const response = await admin
                          .messaging()
                          .send(fcmPayload);
                        console.log("FCM notification sent:", response);
                      } catch (error) {
                        console.error("Error sending FCM:", error);
                      }

                      try {
                        console.log("start insert into notification");
                        await pool.query(
                          "INSERT INTO notifications (device_id, sensor_type, current_value, target_value, timestamp) VALUES (?, ?, ?, ?, NOW())",
                          [
                            deviceId,
                            notification.type,
                            notification.current_value,
                            notification.target_value,
                          ]
                        );
                        console.log("Notification stored in database.");
                      } catch (error) {
                        console.error(
                          "Error storing notification in database:",
                          error
                        );
                      }

                      if (wss) {
                        wss.clients.forEach((client) => {
                          if (client.userId === userId) {
                            client.send(
                              JSON.stringify({
                                type: "sensor_alert",
                                deviceId: deviceId,
                                deviceName: deviceName,
                                title:
                                  notification.title[preferredLanguage] ||
                                  notification.title.en ||
                                  "Alert!",
                                body:
                                  notification.body[preferredLanguage] ||
                                  notification.body.en ||
                                  "Sensor Alert!",
                                alertType: notification.type,
                              })
                            );
                          }
                        });
                      }
                    }
                  }
                } catch (error) {
                  console.error("Error querying user data:", error);
                }
              }
            } catch {
              console.log("Error querying database: ", error);
            }
          } else {
            console.log(`Device with ID ${deviceId} not found.`);
          }
        } catch (error) {
          console.error("Error querying database:", error);
        }
      }
    } else if (topic === sensorAiTopic) {
      const { device_id: aiDeviceId, humidity: aiHumidity } = parsedMessage;
      console.log(
        `AI Sensor Data - Device ID: ${aiDeviceId}, Humidity: ${aiHumidity}`
      );

      if (aiDeviceId) {
        try {
          await pool.query(
            "UPDATE devices SET current_humidity_ai = ? WHERE device_id = ?",
            [aiHumidity, aiDeviceId]
          );
          console.log(
            `Updated humidity_ai for device ${aiDeviceId}: ${aiHumidity}`
          );
        } catch (error) {
          console.error("Error updating AI humidity in database:", error);
        }
      }
    }
  } catch (error) {
    console.error("Error parsing message:", error);
  }
});

clientMqtt.on("error", (err) => {
  console.error("MQTT Error:", err);
});

module.exports = clientMqtt;
module.exports.mqttTopic = sensorDataTopic;
module.exports.mqttAiTopic = sensorAiTopic;
