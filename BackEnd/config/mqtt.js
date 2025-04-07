const mqtt = require('mqtt');
const pool = require('./db');
const admin = require('./firebase');
const { wss } = require('../app');

const mqttHost = 'mqtt://192.168.0.106';
const mqttPort = 1883;
const mqttTopic = 'sensor/data';

const mqttUsername = 'mymqtt';
const mqttPassword = 'paddy';

const clientMqtt = mqtt.connect(mqttHost, {
  port: mqttPort,
  clientId: 'NodeJSClient',
  clean: true,
  username: mqttUsername,
  password: mqttPassword,
});

clientMqtt.on('connect', () => {
  console.log('Connected to MQTT Broker');
  clientMqtt.subscribe(mqttTopic, (err) => {
    if (err) {
      console.error(`Failed to subscribe to topic ${mqttTopic}:`, err);
    } else {
      console.log(`Subscribed to topic: ${mqttTopic}`);
    }
  });
});

clientMqtt.on('message', async (topic, message) => {
  console.log(`Message received from topic ${topic}:`);
  try {
    const sensorData = JSON.parse(message.toString());
    console.log('Sensor Data:', sensorData);
    const deviceId = sensorData.device_id;
    const currentFrontTemp = sensorData.front_temp;
    const currentBackTemp = sensorData.back_temp;
    const currentHumidity = sensorData.humidity;

    if (deviceId) {
      try {
        const [devices] = await pool.query(
          'SELECT target_front_temp, target_back_temp, target_humidity, user_id FROM devices WHERE device_id = ?',
          [deviceId]
        );
        console.log('Devices:', devices);

        if (devices.length > 0) {
          const target = devices[0];
          const userId = target.user_id;
          const targetFrontTemp = target.target_front_temp;
          const targetBackTemp = target.target_back_temp;
          const targetHumidity = target.target_humidity;

          const notificationsToSend = [];

          if (currentFrontTemp > targetFrontTemp) {
            notificationsToSend.push({
              title: `Alert! Front Temp Exceeded Target (${deviceId})`,
              body: `Front Temperature (${currentFrontTemp}°C) exceeds target (${targetFrontTemp}°C)`,
              type: 'front_temp'
            });
          }
          if (currentBackTemp > targetBackTemp) {
            notificationsToSend.push({
              title: `Alert! Back Temp Exceeded Target (${deviceId})`,
              body: `Back Temperature (${currentBackTemp}°C) exceeds target (${targetBackTemp}°C)`,
              type: 'back_temp'
            });
          }
          if (currentHumidity > targetHumidity) {
            notificationsToSend.push({
              title: `Alert! Humidity Exceeded Target (${deviceId})`,
              body: `Humidity (${currentHumidity}%) exceeds target (${targetHumidity}%)`,
              type: 'humidity'
            });
          }

          if (userId && notificationsToSend.length > 0) {
            const [users] = await pool.query('SELECT token FROM users WHERE user_id = ?', [userId]);
            console.log('token:', users);
            if (users.length > 0 && users[0].token) {
              const fcmToken = users[0].token;

              for (const notification of notificationsToSend) {
                const fcmPayload = {
                  notification: { title: notification.title, body: notification.body },
                  data: { deviceId: String(deviceId), type: notification.type },
                  token: fcmToken,
                };
                try {
                  const response = await admin.messaging().send(fcmPayload);
                  console.log('FCM notification sent:', response);
                } catch (error) {
                  console.error('Error sending FCM:', error);
                }

                if (wss) {
                  wss.clients.forEach(client => {
                    if (client.userId === userId) {
                      client.send(JSON.stringify({ type: 'sensor_alert', deviceId: deviceId, title: notification.title, body: notification.body, alertType: notification.type }));
                    }
                  });
                }
              }
            }
          }
        } else {
          console.log(`Device with ID ${deviceId} not found.`);
        }
      } catch (error) {
        console.error('Error querying database:', error);
      }
    }
  } catch (error) {
    console.error('Error parsing message:', error);
  }
});

clientMqtt.on('error', (err) => {
  console.error('MQTT Error:', err);
});

module.exports = clientMqtt;
module.exports.mqttTopic = mqttTopic;