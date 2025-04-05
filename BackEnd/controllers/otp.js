const pool = require('../config/db');
const mailjet = require('../config/mailjet');

function generateOTP() {
  const otp = Math.floor(1000 + Math.random() * 9000);
  return otp;
}

const otpController = {
  sendOTP: async (req, res) => {
    const { email } = req.body;
    if (!email) {
      return res.status(400).send({ message: 'Email is required' });
    }
    const otp = generateOTP();
    const request = mailjet.post('send', { version: 'v3.1' }).request({
      Messages: [
        {
          From: { Email: 'apinya61145@gmail.com', Name: 'RiceTempAlertPro' },
          To: [{ Email: email, Name: 'User' }],
          Subject: 'Your OTP Code',
          TextPart: `Your OTP code is ${otp}`,
          HTMLPart: `<h3>Your OTP code is: <strong>${otp}</strong></h3>`,
        },
      ],
    });
    try {
      const result = await request;
      console.log('Email successfully sent:', result.body);
      return res.status(200).send({ message: 'OTP sent successfully', otp });
    } catch (err) {
        console.log(err.statusCode);
        console.error('Failed to send email:', err);
        return res.status(500).send({ message: 'Failed to send OTP' });
      }
    },
  
    checkUserExists: async (req, res) => {
      const { email } = req.body;
      if (!email) {
        return res.status(400).send({ message: 'Email is required' });
      }
      try {
        const [results] = await pool.query('SELECT email FROM users WHERE email = ?', [email]);
        if (results.length > 0) {
          return res.status(200).send({ exists: true });
        } else {
          return res.status(404).send({ exists: false });
        }
      } catch (err) {
        console.error('Database query error:', err);
        return res.status(500).send({ message: 'Database error' });
      }
    },
  };
  
  module.exports = otpController;