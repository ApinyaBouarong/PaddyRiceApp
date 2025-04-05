const express = require('express');
const router = express.Router();
const authRoutes = require('./auth');
const deviceRoutes = require('./device');
const profileRoutes = require('./profile');
const otpController = require('../controllers/otp');
const admin = require('../config/firebase');
const clientMqtt = require('../config/mqtt');
const { mqttTopic } = require('../config/mqtt');

router.use('/', authRoutes);
router.use('/', deviceRoutes);
router.use('/', profileRoutes);

router.post('/sendToken', async (req, res) => {
  console.log('Received request to send token');
  const { userId, token } = req.body;

  if (!token || !userId) {
    return res.status(400).send({ message: 'Token and User ID are required' });
  }

  try {
    const [results] = await pool.query('SELECT user_id FROM users WHERE user_id = ?', [userId]);
    if (results.length === 0) {
      return res.status(404).send({ message: 'User not found' });
    }
    const [updateResults] = await pool.query('UPDATE users SET token = ? WHERE user_id = ?', [token, userId]);
    if (updateResults.affectedRows === 0) {
      return res.status(500).send({ message: 'Failed to update token' });
    }
    res.status(200).send({ message: 'Token updated successfully' });
    console.log('Token updated successfully:', token);
  } catch (err) {
    console.error('Database error:', err);
    return res.status(500).send({ message: 'Database error' });
  }
});

router.post('/send-notification', async (req, res) => {
  const token = req.body.token;
  const title = req.body.title;
  const body = req.body.body;

  console.log('Received request to send notification:', { token, title, body });

  try {
    const message = {
      notification: {
        title: title,
        body: body,
      },
      token: token,
    };

    const response = await admin.messaging().send(message);
    console.log('Successfully sent message notification:', response);
    res.status(200).json({ message: 'Notification sent successfully', response: response });
  } catch (error) {
    console.error('Error sending message notification:', error);
    res.status(500).json({ error: 'Failed to send notification', details: error.message });
  }
});

router.post('/send-otp', otpController.sendOTP);
router.post('/check-user-exists', otpController.checkUserExists);

module.exports = router;