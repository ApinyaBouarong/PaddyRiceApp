const mysql = require("mysql2");

const pool = mysql.createPool({
  host: "127.0.0.1",
  user: "root",
  password: "root",
  database: "paddy_app",
  charset: "utf8mb4",
});

module.exports = pool.promise();
