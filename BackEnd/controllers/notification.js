const pool = require("../config/db");

const notificationController = {
  getNotification: async (req, res) => {
    console.log("start get notification");
    const deviceIdString = req.params.deviceId;
    const deviceId = parseInt(deviceIdString, 10);
    try {
      const [rows] = await pool.query(
        "SELECT * FROM notifications WHERE device_id = ? ORDER BY timestamp DESC",
        [deviceId]
      );
      if (rows.length > 0) {
        return res.status(200).json(rows);
      } else {
        return res
          .status(404)
          .json({ message: "No notifications found for this device" });
      }
    } catch (error) {
      console.error("Error fetching notifications:", error);
      return res
        .status(500)
        .json({ error: "Failed to retrieve notifications" });
    }
  },
};

module.exports = notificationController;
