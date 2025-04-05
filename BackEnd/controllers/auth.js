const pool = require('../config/db');
const bcrypt = require('bcrypt');

const authController = {
  login: async (req, res) => {
    const { emailOrPhone, password } = req.body;
    try {
      const [rows] = await pool.query(
        'SELECT user_id, password FROM users WHERE email = ? OR phone_number = ?',
        [emailOrPhone, emailOrPhone]
      );
      if (rows.length === 0) {
        return res.status(401).json({ message: 'Invalid email or phone number' });
      }
      const user = rows[0];
      const isPasswordCorrect = await bcrypt.compare(password, user.password);
      if (!isPasswordCorrect) {
        return res.status(401).json({ message: 'Incorrect password' });
      }
      res.status(200).json({ user_id: user.user_id });
      console.log('User logged in:', user.user_id);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Server error' });
    }
  },

  signup: async (req, res) => {
    const { name, surname, phone, email, password } = req.body;
    try {
      const [existingUsers] = await pool.query(
        'SELECT * FROM users WHERE email = ? OR phone_number = ?',
        [email, phone]
      );
      if (existingUsers.length > 0) {
        return res.status(409).json({ message: 'Email or phone already exists' });
      }
      const hashedPassword = await bcrypt.hash(password, 10);
      await pool.query(
        'INSERT INTO users (name, surname, phone_number, email, password) VALUES (?, ?, ?, ?, ?)',
        [name, surname, phone, email, hashedPassword]
      );
      res.status(201).json({ message: 'User registered successfully' });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Server error' });
    }
  },
};

module.exports = authController;