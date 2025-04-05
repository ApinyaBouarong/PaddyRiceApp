const session = require('express-session');
const MySQLStore = require('express-mysql-session')(session);
const pool = require('./db');

const sessionStore = new MySQLStore({}, pool);

module.exports = { sessionStore };