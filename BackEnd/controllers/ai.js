const mqttClient = require("../config/mqtt");
const pool = require("../config/db");

const client = mqttClient;

const topic = mqttClient.mqttTopic;

const aiController = {
  start: async (req, res) => {
    console.log("Start AI");

    const humidity = req.body.humidity;
    const device_id = req.body.deviceId;

    try {
      // const query =
      //   "INSERT INTO device_readings (start_humidity, device_id) VALUES (?, ?)";
      // const values = [humidity, device_id];

      // const [results] = await pool.query(query, values);

      // console.log("Data inserted successfully:", results);

      const payload = JSON.stringify({
        command: "start",
        humidity: humidity,
        deviceId: device_id,
      });

      client.publish("sensor/ai/control", payload);
      res.send({ status: "AI started", humidity, device_id });
    } catch (error) {
      console.error("Error inserting data or sending MQTT:", error);
      res.status(500).send({ error: "Failed to start AI" });
    }
  },

  stop: async (req, res) => {
    console.log("Stop AI");
    const device_id = req.body.deviceId;

    const payload = JSON.stringify({
      command: "stop",
      deviceId: device_id,
    });
    client.publish("sensor/ai/control", payload);
    res.send({ status: "AI stopped" });
  },
};

module.exports = aiController;
