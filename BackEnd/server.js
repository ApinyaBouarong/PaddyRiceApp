const express = require('express');
const bodyParser = require('body-parser');
const session = require('express-session');
const mysql = require('mysql2');
const bcrypt = require('bcrypt');
const cors = require('cors');
const MySQLStore = require('express-mysql-session')(session);
const mailjet = require('node-mailjet');
const mqtt = require('mqtt');
const WebSocket = require('ws');

const mqttHost = 'mqtt://192.168.137.91';
const mqttPort = 1883;
const mqttTopic = 'sensor/data';

const client = mailjet.apiConnect(
    '22a0bc71b4589e0eee7501bc18b783cd',
    '2178197b69175dadf0c6d8a1229a20e4'
);

const clientMqtt = mqtt.connect(mqttHost, {
    port: mqttPort,
    clientId: 'NodeJSClient',
    clean: true,
});
//Firebase Cloud Messaging ไม่ใช้ webSocket
const app = express();
const port = 3030;
const wss = new WebSocket.Server({ port: 8088 });
let mqttData = {};

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

const pool = mysql.createPool({
  host: '127.0.0.1',
  user: 'root',
  password: 'root',
  database: 'paddy_app',
});

const sessionStore = new MySQLStore({}, pool.promise());

app.use(session({
  key: 'session_cookie_name',
  secret: 'session_cookie_secret',
  store: sessionStore,
  resave: false,
  saveUninitialized: false,
  cookie: { maxAge: 1000 * 60 * 60 * 24 },
}));

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

// app.get('/api/data', (req, res) => {
//     const device_id = req.query.device_id;
//     if (!device_id) {
//       return res.status(400).json({ error: 'Device ID is required' });
//     }

//     const query = `
//       SELECT
//         target_front_temp,
//         target_back_temp,
//         target_humidity
//       FROM devices
//       WHERE device_id = ?`;

//     pool.query(query, [device_id], (err, results) => {
//       if (err) {
//         return res.status(500).json({ error: 'Database query error', details: err.message });
//       }
//       if (results.length === 0) {
//         return res.status(404).json({ error: 'Device ID not found' });
//       }
//       res.json(results[0]);
//     });
// });

app.post('/sendToken', (req, res) => {
    console.log('Received request to send token');
    const { userId, token } = req.body;

    if (!token || !userId) {
        return res.status(400).send({ message: 'Token and User ID are required' });
    }

    const query = 'SELECT user_id FROM users WHERE user_id = ?';
    pool.query(query, [userId], (err, results) => {
        if (err) {
            console.error('Database query error:', err);
            return res.status(500).send({ message: 'Database error' });
        }
        if (results.length === 0) {
            return res.status(404).send({ message: 'User not found' });
        }

        const updateQuery = 'UPDATE users SET token = ? WHERE user_id = ?';
        pool.query(updateQuery, [token, userId], (updateErr, updateResults) => {
            if (updateErr) {
                console.error('Database update error:', updateErr);
                return res.status(500).send({ message: 'Database error' });
            }
            if (updateResults.affectedRows === 0) {
                return res.status(500).send({ message: 'Failed to update token' });
            }
            res.status(200).send({ message: 'Token updated successfully' });
            console.log('Token updated successfully:', token);
        });
    });
});

// ฟังก์ชันสำหรับสร้าง OTP แบบสุ่ม
function generateOTP() {
    const otp = Math.floor(1000 + Math.random() * 9000); // สร้างเลข 4 หลักแบบสุ่ม
    return otp;
}
// API สำหรับส่ง OTP ไปยังอีเมล
app.post('/send-otp', (req, res) => {
    const { email } = req.body; // รับอีเมลจากคำร้อง

    if (!email) {
        return res.status(400).send({ message: 'Email is required' });
    }

    // สร้าง OTP
    const otp = generateOTP();

    // ข้อความอีเมลที่จะส่ง
    const request = client
        .post("send", { version: 'v3.1' })
        .request({
            Messages: [
                {
                    From: {
                        Email: "apinya61145@gmail.com", // อีเมลผู้ส่ง
                        Name: "RiceTempAlertPro" // ชื่อผู้ส่ง
                    },
                    To: [
                        {
                            Email: email, // อีเมลผู้รับที่ได้จาก request
                            Name: "User"
                        }
                    ],
                    Subject: "Your OTP Code",
                    TextPart: `Your OTP code is ${otp}`, // OTP ที่จะส่งไป
                    HTMLPart: `<h3>Your OTP code is: <strong>${otp}</strong></h3>`
                }
            ]

        });

    // ส่งอีเมลและตอบกลับ
    request
        .then((result) => {
            console.log(result.body);
            console.log('Email successfully sent:', result.body);  // ตรวจสอบข้อความใน console
            return res.status(200).send({ message: 'OTP sent successfully', otp });
        })
        .catch((err) => {
            console.log(err.statusCode);
            console.error('Failed to send email:', err);  // ตรวจสอบข้อผิดพลาด
            return res.status(500).send({ message: 'Failed to send OTP' });
        });
});

app.post('/check-user-exists', (req, res) => {
    const { email } = req.body;

    if (!email) {
        return res.status(400).send({ message: 'Email is required' });
    }

    // Query เพื่อตรวจสอบว่ามีอีเมลนี้อยู่ในฐานข้อมูลหรือไม่
    pool.query('SELECT email FROM users WHERE email = ?', [email], (err, results) => {
        if (err) {
            console.error('Database query error:', err);
            return res.status(500).send({ message: 'Database error' });
        }

        if (results.length > 0) {
            return res.status(200).send({ exists: true }); // อีเมลนี้มีอยู่ในระบบ
        } else {
            return res.status(404).send({ exists: false }); // ไม่พบอีเมลนี้
        }
    });
});

// Login route
app.post('/login', async (req, res) => {
    const { emailOrPhone, password } = req.body;

    try {
        const [rows] = await pool.promise().query(
            'SELECT user_id, password FROM users WHERE email = ? OR phone_number = ?',
            [emailOrPhone, emailOrPhone]
        );

        if (rows.length === 0) {
            return res.status(401).json({ message: 'Invalid email or phone number' });
        }
        console.log(rows);
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
});

// Signup route
app.post('/signup', async (req, res) => {
    const { name, surname, phone, email, password } = req.body;

    try {
        const [existingUsers] = await pool.promise().query(
            'SELECT * FROM users WHERE email = ? OR phone_number = ?',
            [email, phone]
        );

        if (existingUsers.length > 0) {
            return res.status(409).json({ message: 'Email or phone already exists' });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        await pool.promise().query(
            'INSERT INTO users (name, surname, phone_number, email, password) VALUES (?, ?, ?, ?, ?)',
            [name, surname, phone, email, hashedPassword]
        );

        res.status(201).json({ message: 'User registered successfully' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Route to get user profile by email
app.get('/profile', async (req, res) => {
    const { email } = req.query;

    try {
        const [rows] = await pool.promise().query(
            'SELECT name, surname, email, phone_number FROM users WHERE email = ?',
            [email]
        );

        if (rows.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        const user = rows[0];
        res.status(200).json(user);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

app.get('/profile/:userId', async (req, res) => {
    const userId = req.params.userId;
    const sql = 'SELECT name, surname, email, phone_number FROM users WHERE user_id = ?';
    pool.query(sql, [userId], (err, results) => {
        if (err) {
            console.error('Database query error:', err);
            return res.status(500).send('Error on the server.');
        }
        if (results.length === 0) {
            return res.status(404).send('User not found');
        }
        const user = results[0];
        res.status(200).json(user);
    });
});
app.put('/profile/:userId', async (req, res) => {
    const userId = req.params.userId;
    const { name, surname, email, phone } = req.body;

    // ตรวจสอบว่าข้อมูลที่จำเป็นถูกส่งมาครบหรือไม่
    if (!name || !surname || !email || !phone) {
        return res.status(400).json({ message: 'All fields are required' });
    }

    try {
        const query = 'UPDATE users SET name = ?, surname = ?, email = ?, phone_number = ? WHERE user_id = ?';
        const [result] = await pool.promise().query(query, [name, surname, email, phone, userId]);

        // ตรวจสอบว่ามีการอัปเดตข้อมูลจริงหรือไม่
        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'User not found or no changes made' });
        }

        res.status(200).json({ message: 'Profile updated successfully' });
    } catch (error) {
        console.error('Error updating profile:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

// ฟังก์ชันสำหรับเปลี่ยนรหัสผ่าน
app.post('/change-password', (req, res) => {
    const { userId, currentPassword, newPassword } = req.body;

    // ตรวจสอบผู้ใช้ในฐานข้อมูลจาก id
    const query = 'SELECT * FROM users WHERE user_id = ?';
    pool.query(query, [userId], (err, results) => {
      if (err) return res.status(500).send({ message: 'Database error' });
      if (results.length === 0) return res.status(404).send({ message: 'User not found' });

      const user = results[0];

      // ตรวจสอบว่ารหัสผ่านปัจจุบันถูกต้องหรือไม่
      const isPasswordValid = bcrypt.compareSync(currentPassword, user.password);
      if (!isPasswordValid) {
        return res.status(401).send({ message: 'Current password is incorrect' });
      }

      // เข้ารหัสรหัสผ่านใหม่
      const hashedPassword = bcrypt.hashSync(newPassword, 8);

      // อัปเดตฐานข้อมูลด้วยรหัสผ่านใหม่
      const updateQuery = 'UPDATE users SET password = ? WHERE id = ?';
      pool.query(updateQuery, [hashedPassword, userId], (err, results) => {
        if (err) return res.status(500).send({ message: 'Error updating password' });

        res.status(200).send({ message: 'Password changed successfully' });
      });
    });
});

app.post('/change_password', (req, res) => {
    const { userId, newPassword } = req.body;

    // ตรวจสอบผู้ใช้ในฐานข้อมูลจาก id
    const query = 'SELECT * FROM users WHERE user_id = ?';
    pool.query(query, [userId], (err, results) => {
        if (err) return res.status(500).send({ message: 'Database error' });
        if (results.length === 0) return res.status(404).send({ message: 'User not found' });

        // เข้ารหัสรหัสผ่านใหม่
        const hashedPassword = bcrypt.hashSync(newPassword, 8);

        // อัปเดตฐานข้อมูลด้วยรหัสผ่านใหม่
        const updateQuery = 'UPDATE users SET password = ? WHERE id = ?';
        pool.query(updateQuery, [hashedPassword, userId], (err, results) => {
            if (err) return res.status(500).send({ message: 'Error updating password' });

            res.status(200).send({ message: 'Password changed successfully' });
        });
    });
});

app.get('/user/devices/:userId', (req, res) => {
    const userId = req.params.userId;

    pool.query('SELECT * FROM devices WHERE user_id = ?', [userId], (err, results) => {
        if (err) {
            console.error('Error fetching devices:', err);
            return res.status(500).send({ message: 'Database error' });
        }
        res.status(200).json(results);
    });
});

// API สำหรับดึงข้อมูลอุปกรณ์ทั้งหมด
app.get('/devices', (req, res) => {
    pool.query('SELECT * FROM devices', (err, results) => {
      if (err) {
        console.error('Error fetching devices:', err);
        return res.status(500).send({ message: 'Database error' });
      }
      res.status(200).json(results);
    });
});

// API สำหรับเพิ่มอุปกรณ์ใหม่
// app.post('/devices', (req, res) => {
//     const { name, id, status } = req.body;

//     if (!name || !id) {
//       return res.status(400).send({ message: 'Name and ID are required' });
//     }

//     pool.query(
//       'INSERT INTO devices (name, id, status) VALUES (?, ?, ?)',
//       [name, id, status ? 1 : 0],
//       (err, results) => {
//         if (err) {
//           console.error('Error adding device:', err);
//           return res.status(500).send({ message: 'Database error' });
//         }
//         res.status(201).send({ message: 'Device added successfully' });
//       }
//     );
// });

// // API สำหรับอัปเดตข้อมูลอุปกรณ์ในฐานข้อมูล
app.put('/devices/:id', (req, res) => {
    const deviceId = req.params.id;
    const { front_temp, back_temp, humidity } = req.body;

    pool.query(
      'UPDATE device_readings SET front_temp = ?, back_temp = ?, humidity = ? WHERE device_id = ?',
      [front_temp, back_temp, humidity, deviceId],
      (err, results) => {
        if (err) {
          console.error('Error updating device:', err);
          return res.status(500).send({ message: 'Database error' });
        }
        if (results.affectedRows === 0) {
          return res.status(404).send({ message: 'Device not found' });
        }
        res.status(200).send({ message: 'Device updated successfully' });
      }
    );
});

// ดึงค่า status ของอุปกรณ์
// app.get('/devices/:deviceId/status', (req, res) => {
//     const deviceId = req.params.deviceId;

//     pool.query(
//         'SELECT status FROM devices WHERE device_id = ?',
//         [deviceId],
//         (err, results) => {
//             if (err) {
//                 console.error('Error fetching device status:', err);
//                 return res.status(500).send({ message: 'Database error' });
//             }

//             if (results.length === 0) {
//                 return res.status(404).send({ message: 'Device not found' });
//             }

//             res.status(200).json(results[0]);
//         }
//     );
// });

// API สำหรับลบอุปกรณ์
// app.delete('/devices/:id', (req, res) => {
//     const deviceId = req.params.id;

//     pool.query('DELETE FROM devices WHERE device_id = ?', [deviceId], (err, results) => {
//       if (err) {
//         console.error('Error deleting device:', err);
//         return res.status(500).send({ message: 'Database error' });
//       }
//       if (results.affectedRows === 0) {
//         return res.status(404).send({ message: 'Device not found' });
//       }
//       res.status(200).send({ message: 'Device deleted successfully' });
//     });
// });

// API สำหรับดึงข้อมูลอุปกรณ์ล่าสุดจากฐานข้อมูล
// app.get('/devices/:deviceId/temperature', (req, res) => {
//     const deviceId = req.params.deviceId;

//     pool.query(
//       'SELECT front_temp, back_temp, humidity FROM device_readings WHERE device_id = ? ORDER BY recorded_at DESC LIMIT 1',
//       [deviceId],
//       (err, results) => {
//         if (err) {
//           console.error('Error fetching device temperature:', err);
//           return res.status(500).send({ message: 'Database error' });
//         }

//         if (results.length === 0) {
//           return res.status(404).send({ message: 'No temperature data found for this device' });
//         }

//         res.status(200).json(results[0]);
//       }
//     );
// });

app.put('/devices/:id', (req, res) => {
  const deviceId = req.params.id;
  const { target_front_temp, target_back_temp, target_humidity } = req.body;

  pool.query(
    'UPDATE devices SET target_front_temp = ?, target_back_temp = ?, target_humidity = ? WHERE device_id = ?',
    [target_front_temp, target_back_temp, target_humidity, deviceId],
    (err, results) => {
      if (err) {
        console.error('Error updating device:', err);
        return res.status(500).send({ message: 'Database error' });
      }
      if (results.affectedRows === 0) {
        return res.status(404).send({ message: 'Device not found' });
      }
      res.status(200).send({ message: 'Target values updated successfully' });
    }
  );
});

app.put('/update-device', (req, res) => {
    const { deviceId, deviceName, targetFrontTemp, targetBackTemp, targetHumidity } = req.body;
    console.log(`Updating device: ${deviceId}, New Name: ${deviceName},tar_front: ${targetFrontTemp}`);

    const query = `
      UPDATE devices
      SET device_name = ?, target_front_temp = ?, target_back_temp = ?, target_humidity = ?
      WHERE device_id = ?;
    `;

    pool.query(
      query,
      [deviceName, targetFrontTemp, targetBackTemp, targetHumidity, deviceId],
      (err, result) => {
        if (err) {
          console.error(err);
          return res.status(500).send({ message: 'Database error' });
        }
        res.status(200).send({ message: 'Device and target values updated successfully' });
      }
    );
});
app.get('/devices/:deviceId/target-values', (req, res) => {
    const deviceId = req.params.deviceId;

    pool.query(
        'SELECT device_name, target_front_temp, target_back_temp, target_humidity FROM devices WHERE device_id = ?',
        [deviceId],
        (err, results) => {
            if (err) {
                console.error('Error fetching target values:', err);
                return res.status(500).send({ message: 'Database error' });
            }

            if (results.length === 0) {
                return res.status(404).send({ message: 'No target values found for this device' });
            }

            res.status(200).json(results[0]);
            console.log(results[0]);
        }
    );
});

// Listen on port 3000
app.listen(port, '0.0.0.0', () => {
    console.log(`Server running on http://localhost:${port}`);
});
