const express = require('express');
const router = express.Router();
const deviceController = require('../controllers/device');

router.get('/devices', deviceController.getDevices);
router.get('/user/devices/:userId', deviceController.getDevicesByUser);
router.put('/devices/:id', deviceController.updateDeviceReadings);
router.put('/update-device', deviceController.updateDevice);
router.get('/devices/:deviceId/target-values', deviceController.getTargetValues);

module.exports = router;