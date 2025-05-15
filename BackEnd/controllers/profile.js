const pool = require("../config/db");
const bcrypt = require("bcrypt");

const profileController = {
  getProfileByEmail: async (req, res) => {
    const { email } = req.query;
    try {
      const [rows] = await pool.query(
        "SELECT name, surname, email, phone_number FROM users WHERE email = ?",
        [email]
      );
      if (rows.length === 0) {
        return res.status(404).json({ message: "User not found" });
      }
      const user = rows[0];
      res.status(200).json(user);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: "Server error" });
    }
  },

  getProfileByUserId: async (req, res) => {
    const userIdString = req.params.userId;
    const userId = parseInt(userIdString);
    console.log("Get profile userid:", userId);
    try {
      const [rows] = await pool.query(
        "SELECT name, surname, email, phone_number FROM users WHERE user_id = ?",
        [userId]
      );
      if (rows.length === 0) {
        return res.status(404).send("User not found");
      }
      const user = rows[0];
      res.status(200).json(user);
    } catch (error) {
      console.error("Database query error:", error);
      return res.status(500).send("Error on the server.");
    }
  },

  updateProfile: async (req, res) => {
    const userId = req.params.userId;
    const { name, surname, email, phone_number } = req.body;
    console.log("Update profile:", userId, name, surname, email, phone_number);
    if (!name || !surname || !email || !phone_number) {
      return res.status(400).json({ message: "All fields are required" });
    }
    try {
      const [result] = await pool.query(
        "UPDATE users SET name = ?, surname = ?, email = ?, phone_number = ? WHERE user_id = ?",
        [name, surname, email, phone_number, userId]
      );
      console.log("Update result:", result);
      if (result.affectedRows === 0) {
        return res
          .status(404)
          .json({ message: "User not found or no changes made" });
      }
      if (res.statusCode === 200) {
        console.log("Profile updated successfully");
        res.status(200).json({ message: "Profile updated successfully" });
      }
    } catch (error) {
      console.error("Error updating profile:", error);
      res.status(500).json({ message: "Server error" });
    }
  },

  changePassword: async (req, res) => {
    const { userId, currentPassword, newPassword } = req.body;
    try {
      const [rows] = await pool.query("SELECT * FROM users WHERE user_id = ?", [
        userId,
      ]);
      if (rows.length === 0)
        return res.status(404).send({ message: "User not found" });
      const user = rows[0];
      const isPasswordValid = await bcrypt.compare(
        currentPassword,
        user.password
      );
      if (!isPasswordValid) {
        return res
          .status(401)
          .send({ message: "Current password is incorrect" });
      }
      const hashedPassword = await bcrypt.hash(newPassword, 8);
      await pool.query("UPDATE users SET password = ? WHERE user_id = ?", [
        hashedPassword,
        userId,
      ]);
      res.status(200).send({ message: "Password changed successfully" });
    } catch (error) {
      console.error(error);
      return res.status(500).send({ message: "Database error" });
    }
  },
};

module.exports = profileController;
