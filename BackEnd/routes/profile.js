const express = require('express');
const router = express.Router();
const profileController = require('../controllers/profile');

router.get('/profile', profileController.getProfileByEmail);
router.get('/profile/:userId', profileController.getProfileByUserId);
router.put('/profile/:userId', profileController.updateProfile);
router.post('/change-password', profileController.changePassword);
router.post('/change_password', profileController.changePassword);

module.exports = router;