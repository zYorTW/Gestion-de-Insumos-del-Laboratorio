const http = require('http');

const BASE = 'http://localhost:4000';
let TOKEN = '';
const results = [];

function req(method, path, body, auth) {
  return new Promise((resolve) => {
    const opts = {
      hostname: 'localhost', port: 4000, path, method,
      headers: {
        'Content-Type': 'application/json',
        ...(auth && TOKEN ? { Authorization: `Bearer ${TOKEN}` } : {})
      }
    };
    const r = http.request(opts, (res) => {
      let data = '';
      res.on('data', d => data += d);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(data) }); }
        catch { resolve({ status: res.statusCode, body: data.slice(0, 120) }); }
      });
    });
    r.on('error', e => resolve({ status: 0, body: e.message }));
    if (body) r.write(JSON.stringify(body));
    r.end();
  });
}

function ok(status) { return status >= 200 && status < 300; }

async function test(label, method, path, body, auth) {
  const r = await req(method, path, body, auth);
  const pass = ok(r.status);
  const icon = pass ? '✅' : '❌';
  let preview = '';
  if (pass && r.body) {
    if (Array.isArray(r.body)) preview = `[${r.body.length} items]`;
    else if (typeof r.body === 'object') {
      const keys = Object.keys(r.body).slice(0, 4);
      preview = '{' + keys.join(', ') + (Object.keys(r.body).length > 4 ? '...' : '') + '}';
    }
  } else if (!pass) {
    preview = JSON.stringify(r.body).slice(0, 100);
  }
  const line = `${icon} ${r.status}  ${method.padEnd(6)} ${path.padEnd(50)} ${preview}`;
  console.log(line);
  results.push({ pass, label, status: r.status });
  return r;
}

(async () => {
  console.log('='.repeat(90));
  console.log('TEST DE ENDPOINTS - Backend Laboratorio');
  console.log('='.repeat(90));

  // ── AUTH ──────────────────────────────────────────────────────────────────
  console.log('\n[AUTH]');
  const login = await req('POST', '/api/auth/login', {
    email: 'superadmin@gmail.com', contrasena: '123456'
  });
  if (login.status === 200 && login.body.token) {
    TOKEN = login.body.token;
    console.log('✅ 200  POST   /api/auth/login                                     token obtenido');
    results.push({ pass: true, label: 'POST /api/auth/login', status: 200 });
  } else {
    console.log('❌', login.status, ' POST   /api/auth/login', JSON.stringify(login.body).slice(0, 100));
    results.push({ pass: false, label: 'POST /api/auth/login', status: login.status });
  }
  await test('GET /api/auth/me', 'GET', '/api/auth/me', null, true);

  // ── USUARIOS ──────────────────────────────────────────────────────────────
  console.log('\n[USUARIOS]');
  await test('GET /api/usuarios/roles',    'GET', '/api/usuarios/roles');
  await test('GET /api/usuarios',           'GET', '/api/usuarios');

  // ── DASHBOARD ─────────────────────────────────────────────────────────────
  console.log('\n[DASHBOARD]');
  await test('GET metricas-principales',       'GET', '/api/dashboard/metricas-principales');
  await test('GET reactivos-proximos-vencer',  'GET', '/api/dashboard/reactivos-proximos-vencer');

  // ── REACTIVOS ─────────────────────────────────────────────────────────────
  console.log('\n[REACTIVOS]');
  await test('GET /api/reactivos/aux',          'GET', '/api/reactivos/aux');
  await test('GET /api/reactivos/catalogo',     'GET', '/api/reactivos/catalogo');
  await test('GET /api/reactivos/total',        'GET', '/api/reactivos/total');
  await test('GET /api/reactivos',              'GET', '/api/reactivos');

  // ── INSUMOS ───────────────────────────────────────────────────────────────
  console.log('\n[INSUMOS]');
  await test('GET /api/insumos/aux',            'GET', '/api/insumos/aux');
  await test('GET /api/insumos/catalogo',       'GET', '/api/insumos/catalogo');
  await test('GET /api/insumos',                'GET', '/api/insumos');

  // ── PAPELERÍA ─────────────────────────────────────────────────────────────
  console.log('\n[PAPELERÍA]');
  await test('GET /api/papeleria/catalogo',     'GET', '/api/papeleria/catalogo');
  await test('GET /api/papeleria',              'GET', '/api/papeleria');

  // ── SOLICITUDES ───────────────────────────────────────────────────────────
  console.log('\n[SOLICITUDES]');
  await test('GET /api/solicitudes/departamentos', 'GET', '/api/solicitudes/departamentos');
  await test('GET /api/solicitudes/ciudades',      'GET', '/api/solicitudes/ciudades');
  await test('GET /api/solicitudes/clientes',      'GET', '/api/solicitudes/clientes');
  await test('GET /api/solicitudes',               'GET', '/api/solicitudes');
  await test('GET /api/solicitudes/detalle/lista', 'GET', '/api/solicitudes/detalle/lista');

  // ── LOGS ──────────────────────────────────────────────────────────────────
  console.log('\n[LOGS]');
  await test('GET /api/logs/acciones',              'GET', '/api/logs/acciones');
  await test('GET /api/logs/movimientos-inventario','GET', '/api/logs/movimientos-inventario');
  await test('GET /api/logs/estadisticas',          'GET', '/api/logs/estadisticas');

  // ── EQUIPOS ───────────────────────────────────────────────────────────────
  console.log('\n[EQUIPOS]');
  await test('GET /api/equipos',                   'GET', '/api/equipos');
  await test('GET /api/equipos/fichas-tecnicas',   'GET', '/api/equipos/fichas-tecnicas');

  // ── VOLUMÉTRICOS ──────────────────────────────────────────────────────────
  console.log('\n[VOLUMÉTRICOS]');
  await test('GET /api/volumetricos/materiales',   'GET', '/api/volumetricos/materiales');
  await test('GET /api/volumetricos',              'GET', '/api/volumetricos');

  // ── REFERENCIA ────────────────────────────────────────────────────────────
  console.log('\n[REFERENCIA]');
  await test('GET /api/referencia/material',       'GET', '/api/referencia/material');

  // ── REPORTES (requiere rol Administrador) ────────────────────────────────
  console.log('\n[REPORTES]');
  // Login como admin para obtener token con rol correcto
  const loginAdmin = await req('POST', '/api/auth/login', { email: 'admin@gmail.com', contrasena: '123456' });
  const ADMIN_TOKEN = loginAdmin.body?.token || '';
  console.log(`  (login admin: ${loginAdmin.status} rol=${loginAdmin.body?.rol || loginAdmin.body?.message})`);
  const savedToken = TOKEN;
  if (ADMIN_TOKEN) TOKEN = ADMIN_TOKEN;
  await test('GET /api/reportes/inventario',       'GET', '/api/reportes/inventario',  null, true);
  await test('GET /api/reportes/entradas',         'GET', '/api/reportes/entradas',    null, true);
  await test('GET /api/reportes/salidas',          'GET', '/api/reportes/salidas',     null, true);
  await test('GET /api/reportes/vencimientos',     'GET', '/api/reportes/vencimientos',null, true);
  TOKEN = savedToken;

  // ── RESUMEN ───────────────────────────────────────────────────────────────
  const passed = results.filter(r => r.pass).length;
  const failed = results.filter(r => !r.pass).length;
  console.log('\n' + '='.repeat(90));
  console.log(`RESULTADO: ${passed} OK / ${failed} FALLARON de ${results.length} endpoints`);
  if (failed > 0) {
    console.log('\nFallaron:');
    results.filter(r => !r.pass).forEach(r => console.log(`  ❌ [${r.status}] ${r.label}`));
  }
  console.log('='.repeat(90));
})();
