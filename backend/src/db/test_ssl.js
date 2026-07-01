const mysql = require('mysql2/promise');
const fs = require('fs');

const base = {
  host: 'gateway01.us-east-1.prod.aws.tidbcloud.com',
  port: 4000,
  user: '3XCNBfWUvxfEhKC.root',
  password: 'fEge8yTXgwHoOKmv',
  database: 'liba_db',
  connectTimeout: 8000
};

async function test(label, extra) {
  process.stdout.write(label + ' ... ');
  try {
    const c = await mysql.createConnection({ ...base, ...extra });
    const [[r]] = await c.query('SELECT 1 AS ok, DATABASE() AS db');
    console.log('CONECTADO:', JSON.stringify(r));
    await c.end();
    return true;
  } catch (e) {
    console.log('FALLO:', e.code, '| errno:', e.errno, '| syscall:', e.syscall, '| msg:', e.message);
    return false;
  }
}

(async () => {
  const ca = fs.readFileSync('src/config/certs/ca.pem');

  await test('1. Sin SSL                    ', { ssl: false });
  await test('2. SSL rejectUnauthorized:false', { ssl: { rejectUnauthorized: false } });
  await test('3. SSL CA cert ISRG           ', { ssl: { ca, rejectUnauthorized: false } });
  await test('4. SSL TLSv1.2                ', { ssl: { minVersion: 'TLSv1.2', rejectUnauthorized: false } });
  await test('5. SSL TLSv1.3                ', { ssl: { minVersion: 'TLSv1.3', rejectUnauthorized: false } });
})();
