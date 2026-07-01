require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });
const mysql = require('mysql2/promise');

const cfg = {
  host: process.env.DB_HOST,
  port: 3306,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  connectTimeout: 12000,
  ssl: { rejectUnauthorized: false }
};

(async () => {
  console.log('Conectando a', cfg.host, 'port', cfg.port, 'user', cfg.user, 'db', cfg.database);
  try {
    const conn = await mysql.createConnection(cfg);
    const [[r]] = await conn.query('SELECT 1 AS ok, DATABASE() AS db, VERSION() AS ver');
    console.log('CONECTADO OK:', r);
    const [tables] = await conn.query(
      'SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() ORDER BY TABLE_NAME'
    );
    console.log('Tablas:', tables.map(t => t.TABLE_NAME));
    await conn.end();
  } catch (e) {
    console.log('ERROR:', e.code, e.message);
  }
})();
