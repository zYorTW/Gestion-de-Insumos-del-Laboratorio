require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });
const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');

const base = {
  host: process.env.DB_HOST || process.env.HOST,
  port: Number(process.env.DB_PORT || 4000),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  connectTimeout: 10000
};

const configs = [
  { label: '1. SSL con CA cert + TLSv1.2',       ssl: { ca: fs.readFileSync(path.join(__dirname, '../config/certs/ca.pem')), minVersion: 'TLSv1.2' } },
  { label: '2. SSL minVersion TLSv1.2 (sin CA)',  ssl: { minVersion: 'TLSv1.2' } },
  { label: '3. SSL rejectUnauthorized:false',      ssl: { rejectUnauthorized: false } },
  { label: '4. ssl: true (CA del sistema)',        ssl: true },
  { label: '5. Sin SSL (ssl: false)',              ssl: false },
];

(async () => {
  for (const cfg of configs) {
    process.stdout.write(`Probando ${cfg.label} ... `);
    try {
      const conn = await mysql.createConnection({ ...base, ssl: cfg.ssl, enableKeepAlive: true });
      const [rows] = await conn.query('SELECT 1 AS ok');
      await conn.end();
      console.log('✅ CONECTADO');
      break;
    } catch (e) {
      console.log(`❌ ${e.code || e.message}`);
    }
  }
})();
