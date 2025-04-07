const pool = require('../config/db');

const deviceController = {
  getDevices: async (req, res) => {
    try {
      const [rows] = await pool.query('SELECT * FROM devices');
      res.status(200).json(rows);
    } catch (error) {
      console.error('Error fetching devices:', error);
      return res.status(500).send({ message: 'Database error' });
    }
  },

  getDevicesByUser: async (req, res) => {
    const userId = req.params.userId;
    try {
      const [rows] = await pool.query('SELECT * FROM devices WHERE user_id = ?', [userId]);
      res.status(200).json(rows);
    } catch (error) {
      console.error('Error fetching devices:', error);
      return res.status(500).send({ message: 'Database error' });
    }
  }, 

  updateDeviceReadings: async (req, res) => {
    const deviceId = req.params.id;
    const { front_temp, back_temp, humidity } = req.body;
    try {
      const [result] = await pool.query(
        'UPDATE device_readings SET front_temp = ?, back_temp = ?, humidity = ? WHERE device_id = ?',
        [front_temp, back_temp, humidity, deviceId]
      );
      if (result.affectedRows === 0) {
        return res.status(404).send({ message: 'Device not found' });
      }
      res.status(200).send({ message: 'Device updated successfully' });
    } catch (error) {
      console.error('Error updating device:', error);
      return res.status(500).send({ message: 'Database error' });
    }
  },

  updateDevice: async (req, res) => {
    const { deviceId, deviceName, targetFrontTemp, targetBackTemp, targetHumidity } = req.body;
    console.log(`Updating device: ${deviceId}, New Name: ${deviceName},tar_front: ${targetFrontTemp}`);
    try {
      const [result] = await pool.query(
        `UPDATE devices SET device_name = ?, target_front_temp = ?, target_back_temp = ?, target_humidity = ? WHERE device_id = ?;`,
        [deviceName, targetFrontTemp, targetBackTemp, targetHumidity, deviceId]
      );
      if (result.affectedRows === 0) {
        return res.status(404).send({ message: 'Device not found' });
      }
      res.status(200).send({ message: 'Device and target values updated successfully' });
    } catch (error) {
      console.error(error);
      return res.status(500).send({ message: 'Database error' });
    }
  },

  getTargetValues: async (req, res) => {
    const deviceId = req.params.deviceId;
    try {
      const [rows] = await pool.query(
        'SELECT device_name, target_front_temp, target_back_temp, target_humidity FROM devices WHERE device_id = ?',
        [deviceId]
      );
      if (rows.length === 0) {
        return res.status(404).send({ message: 'No target values found for this device' });
      }
      res.status(200).json(rows[0]);
      console.log(rows[0]);
    } catch (error) {
      console.error('Error fetching target values:', error);
      return res.status(500).send({ message: 'Database error' });
    }
  },

  getDeviceBySerialNumber: async (req, res) => {
    console.log('Received request to get device by serial number');
    const { serialNumber } = req.params;
    try {
      const [rows] = await pool.query('SELECT * FROM devices WHERE serial_number = ?', [serialNumber]);
      if (rows.length > 0) {
        return res.status(200).send({ device: rows[0] });
      } else {
        return res.status(404).send({ exists: false });
      }
    } catch (error) {
      console.error('Error checking serial number:', error);
      return res.status(500).send({ message: 'Database error' });
    }
  },

  updateDeviceBySerialNumber: async (req, res) => {
    const {userId, serialNumber} = req.body;
    console.log(`Received request to update device with serial number: ${serialNumber}, New User ID: ${userId}`);
    try {
      const [result] = await pool.query(
        'UPDATE devices SET user_id = ? WHERE serial_number = ?',
        [userId, serialNumber]
      );
      console.log(`Updating device with serial number: ${serialNumber}, New User ID: ${userId}`);
      if (result.affectedRows === 0) {
        return res.status(404).send({ message: 'Device not found' });
      }
      console.log(`Device with serial number ${serialNumber} updated successfully`);
      res.status(200).send({ message: 'Device updated successfully' });
    }
    catch (error) {
      console.error('Error updating device:', error);
      return res.status(500).send({ message: 'Database error' });
    }
  },

 
};

module.exports = deviceController;