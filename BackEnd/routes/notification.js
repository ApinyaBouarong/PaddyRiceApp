const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notification')

router.get('/notification/:deviceId', notificationController.getNotification );

module.exports = router;