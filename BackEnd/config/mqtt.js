const mqtt = require('mqtt');

const mqttHost = 'mqtt://192.168.137.91';
const mqttPort = 1883;
const mqttTopic = 'sensor/data';

const clientMqtt = mqtt.connect(mqttHost, {
  port: mqttPort,
  clientId: 'NodeJSClient',
  clean: true,
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

clientMqtt.on('message', (topic, message) => {
  console.log(`Message received from topic ${topic}:`);
  try {
    const mqttData = JSON.parse(message.toString());
    console.log('MQTT Data:', mqttData);
  } catch (error) {
    console.error('Error parsing message:', error);
  }
});

clientMqtt.on('error', (err) => {
  console.error('MQTT Error:', err);
});

module.exports = clientMqtt;
module.exports.mqttTopic = mqttTopic;