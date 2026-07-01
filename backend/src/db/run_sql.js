require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });

const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');

async function run() {
  const sql = fs.readFileSync(path.join(__dirname, 'db_completo.sql'), 'utf8');

  // .env usa HOST (no DB_HOST)
  const host = process.env.DB_HOST || process.env.HOST;

  console.log('Conectando a TiDB Cloud...');
  console.log('HOST:', host);
  console.log('DB_PORT:', process.env.DB_PORT);
  console.log('DB_USER:', process.env.DB_USER);
  console.log('DB_NAME:', process.env.DB_NAME);

  const conn = await mysql.createConnection({
    host,
    port: Number(process.env.DB_PORT || 4000),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    ssl: { minVersion: 'TLSv1.2' },
    multipleStatements: true,
    enableKeepAlive: true
  });

  console.log('✅ Conectado a TiDB Cloud. Ejecutando script...');

  try {
    await conn.query(sql);
    console.log('✅ Script SQL ejecutado exitosamente.');
  } catch (err) {
    console.error('❌ Error ejecutando SQL:', err.message);
    process.exit(1);
  } finally {
    await conn.end();
  }
}

run().catch((err) => {
  console.error('❌ Error de conexión:', err.message);
  console.error(err);
  process.exit(1);
});
