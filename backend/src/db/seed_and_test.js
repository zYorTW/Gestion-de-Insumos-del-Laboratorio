const http = require('http');

const BASE = 'http://localhost:4000';
let TOKEN = '';
const results = [];

function req(method, path, body, auth = true) {
  return new Promise((resolve) => {
    const data = body ? JSON.stringify(body) : null;
    const opts = {
      hostname: 'localhost', port: 4000, path, method,
      headers: {
        'Content-Type': 'application/json',
        ...(auth && TOKEN ? { Authorization: `Bearer ${TOKEN}` } : {})
      }
    };
    const r = http.request(opts, (res) => {
      let raw = '';
      res.on('data', d => raw += d);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(raw) }); }
        catch { resolve({ status: res.statusCode, body: raw.slice(0, 100) }); }
      });
    });
    r.on('error', e => resolve({ status: 0, body: e.message }));
    if (data) r.write(data);
    r.end();
  });
}

function log(icon, status, method, path, note = '') {
  console.log(`${icon} ${String(status).padStart(3)}  ${method.padEnd(6)} ${path.padEnd(45)} ${note}`);
}

async function run(label, method, path, body, expectStatus = [200, 201]) {
  const r = await req(method, path, body);
  // 409 on POST = data already exists from a previous seed run — treat as OK
  const softOk = (method === 'POST' && r.status === 409);
  const pass = expectStatus.includes(r.status) || softOk;
  const icon = pass ? (softOk ? '⚠️ ' : '✅') : '❌';
  const note = pass
    ? (typeof r.body === 'object' ? (r.body.message || JSON.stringify(r.body).slice(0, 60)) : '')
    : JSON.stringify(r.body).slice(0, 80);
  log(icon, r.status, method, path, softOk ? '(ya existía)' : note);
  results.push({ pass, label, status: r.status });
  return r;
}

(async () => {
  // ── LOGIN ────────────────────────────────────────────────────────────────
  console.log('\n' + '='.repeat(85));
  console.log('SEED + PRUEBAS DE ESCRITURA — Sistema LIBA');
  console.log('='.repeat(85));

  console.log('\n[1] LOGIN');
  const login = await req('POST', '/api/auth/login', { email: 'superadmin@gmail.com', contrasena: '123456' }, false);
  if (!login.body?.token) { console.log('❌ Login falló:', login.body); process.exit(1); }
  TOKEN = login.body.token;
  log('✅', 200, 'POST', '/api/auth/login', `token obtenido (rol: ${login.body.rol})`);

  // ── CATÁLOGO REACTIVOS ───────────────────────────────────────────────────
  console.log('\n[2] CATÁLOGO REACTIVOS (POST + PUT + DELETE)');
  await run('cat-react-1', 'POST', '/api/reactivos/catalogo', { codigo: 'ACN-001', nombre: 'Acetonitrilo', tipo_reactivo: 'No controlado', clasificacion_sga: 'Inflamables', descripcion: 'Solvente orgánico polar' });
  await run('cat-react-2', 'POST', '/api/reactivos/catalogo', { codigo: 'HCL-001', nombre: 'Ácido Clorhídrico', tipo_reactivo: 'No controlado', clasificacion_sga: 'Corrosivo', descripcion: 'Ácido fuerte 37%' });
  await run('cat-react-3', 'POST', '/api/reactivos/catalogo', { codigo: 'ETO-001', nombre: 'Etanol', tipo_reactivo: 'No controlado', clasificacion_sga: 'Inflamables', descripcion: 'Alcohol etílico 96%' });
  await run('cat-react-4', 'POST', '/api/reactivos/catalogo', { codigo: 'DEL-TMP', nombre: 'Para eliminar', tipo_reactivo: 'No controlado', clasificacion_sga: 'No peligro' });
  await run('cat-react-put', 'PUT', '/api/reactivos/catalogo/ACN-001', { nombre: 'Acetonitrilo HPLC', tipo_reactivo: 'No controlado', clasificacion_sga: 'Inflamables', descripcion: 'Grado HPLC' });
  await run('cat-react-del', 'DELETE', '/api/reactivos/catalogo/DEL-TMP', null, [200]);

  // ── REACTIVOS INVENTARIO ─────────────────────────────────────────────────
  console.log('\n[3] REACTIVOS INVENTARIO (POST + PUT)');
  await run('react-1', 'POST', '/api/reactivos', { lote: 'LOTE-2024-001', codigo: 'ACN-001', nombre: 'Acetonitrilo HPLC', marca: 'Merck', referencia: '1.00030', cas: '75-05-8', presentacion: 1000, presentacion_cant: 1, unidad_id: 1, tipo_id: 2, clasificacion_id: 2, estado_id: 1, tipo_recipiente_id: 1, almacenamiento_id: 14, fecha_adquisicion: '2024-03-15', fecha_vencimiento: '2026-03-15' });
  await run('react-2', 'POST', '/api/reactivos', { lote: 'LOTE-2024-002', codigo: 'HCL-001', nombre: 'Ácido Clorhídrico 37%', marca: 'Carlo Erba', referencia: '404727', cas: '7647-01-0', presentacion: 500, presentacion_cant: 1, unidad_id: 1, tipo_id: 2, clasificacion_id: 3, estado_id: 1, tipo_recipiente_id: 1, almacenamiento_id: 18, fecha_adquisicion: '2024-05-10', fecha_vencimiento: '2027-05-10' });
  await run('react-3', 'POST', '/api/reactivos', { lote: 'LOTE-2024-003', codigo: 'ETO-001', nombre: 'Etanol 96%', marca: 'Panreac', referencia: '211089', cas: '64-17-5', presentacion: 1000, presentacion_cant: 2, unidad_id: 1, tipo_id: 2, clasificacion_id: 2, estado_id: 1, tipo_recipiente_id: 2, almacenamiento_id: 23, fecha_adquisicion: '2024-06-01', fecha_vencimiento: '2026-06-01' });
  await run('react-put', 'PUT', '/api/reactivos/LOTE-2024-001', { codigo: 'ACN-001', nombre: 'Acetonitrilo HPLC Grado A', marca: 'Merck', referencia: '1.00030', cas: '75-05-8', presentacion: 1000, presentacion_cant: 1, unidad_id: 1, tipo_id: 2, clasificacion_id: 2, estado_id: 1, tipo_recipiente_id: 1, almacenamiento_id: 14, fecha_adquisicion: '2024-03-15', fecha_vencimiento: '2026-03-15' });

  // ── CATÁLOGO INSUMOS ─────────────────────────────────────────────────────
  console.log('\n[4] CATÁLOGO INSUMOS (POST)');
  await run('cat-ins-1', 'POST', '/api/insumos/catalogo', { item: 1, nombre: 'Guantes de nitrilo', descripcion: 'Guantes desechables resistentes a químicos' });
  await run('cat-ins-2', 'POST', '/api/insumos/catalogo', { item: 2, nombre: 'Tubos Falcon 50 mL', descripcion: 'Tubos cónicos de polipropileno' });
  await run('cat-ins-3', 'POST', '/api/insumos/catalogo', { item: 3, nombre: 'Micropipeta 1000 µL', descripcion: 'Pipeta de volumen variable 100-1000 µL' });

  // ── INSUMOS INVENTARIO ───────────────────────────────────────────────────
  console.log('\n[5] INSUMOS INVENTARIO (POST + PATCH existencias)');
  const ins1 = await run('ins-1', 'POST', '/api/insumos', { item_catalogo: 1, nombre: 'Guantes de nitrilo talla M', cantidad_adquirida: 100, cantidad_existente: 100, presentacion: 'Caja x100', marca: 'Kimberly-Clark', fecha_adquisicion: '2024-06-01', ubicacion: 'Gabinete Azul- Nivel 1' });
  const ins2 = await run('ins-2', 'POST', '/api/insumos', { item_catalogo: 2, nombre: 'Tubos Falcon 50 mL', cantidad_adquirida: 50, cantidad_existente: 50, presentacion: 'Bolsa x50', marca: 'BD Falcon', fecha_adquisicion: '2024-05-20', ubicacion: 'Estanteria B3- Nivel 2' });
  const ins3 = await run('ins-3', 'POST', '/api/insumos', { item_catalogo: 3, nombre: 'Micropipeta 1000 µL Eppendorf', cantidad_adquirida: 3, cantidad_existente: 3, presentacion: 'Unidad', marca: 'Eppendorf', referencia: '3123000063', fecha_adquisicion: '2023-09-10', ubicacion: 'Nevera MB- Puerta Izquierda' });
  if (ins1.body?.id) await run('ins-patch', 'PATCH', `/api/insumos/${ins1.body.id}/existencias`, { delta: -5, observacion: 'Uso en práctica de bioseguridad' });

  // ── CATÁLOGO PAPELERÍA ───────────────────────────────────────────────────
  console.log('\n[6] CATÁLOGO PAPELERÍA + INVENTARIO (POST + PATCH)');
  await run('cat-pap-1', 'POST', '/api/papeleria/catalogo', { item: 1, nombre: 'Cuaderno de laboratorio', descripcion: 'Cuaderno cuadriculado 100 hojas' });
  await run('cat-pap-2', 'POST', '/api/papeleria/catalogo', { item: 2, nombre: 'Marcadores indelebles', descripcion: 'Marcador permanente negro' });
  const pap1 = await run('pap-1', 'POST', '/api/papeleria', { item_catalogo: 1, nombre: 'Cuaderno de laboratorio 100h', cantidad_adquirida: 10, cantidad_existente: 10, presentacion: 'unidad', marca: 'Norma', fecha_adquisicion: '2024-01-15', ubicacion: 'Estanteria D1- Nivel 1' });
  const pap2 = await run('pap-2', 'POST', '/api/papeleria', { item_catalogo: 2, nombre: 'Marcador Sharpie negro', cantidad_adquirida: 24, cantidad_existente: 24, presentacion: 'caja', marca: 'Sharpie', fecha_adquisicion: '2024-02-10', ubicacion: 'Estanteria D1- Nivel 2' });
  if (pap1.body?.id) await run('pap-patch', 'PATCH', `/api/papeleria/${pap1.body.id}/existencias`, { delta: -2, observacion: 'Entregados a practicantes' });

  // ── CLIENTES + SOLICITUDES ───────────────────────────────────────────────
  console.log('\n[7] CLIENTES + SOLICITUDES (POST + PUT)');
  const cli1 = await run('cli-1', 'POST', '/api/solicitudes/clientes', { nombre_solicitante: 'Universidad Nacional de Colombia', tipo_identificacion: 'NIT', numero_identificacion: '899999063-3', correo_electronico: 'laboratorio@unal.edu.co', celular: '3001234567', id_departamento: '11', id_ciudad: '11001', tipo_usuario: 'Persona Jurídica', razon_social: 'Universidad Nacional de Colombia' });
  const cli2 = await run('cli-2', 'POST', '/api/solicitudes/clientes', { nombre_solicitante: 'Carlos Andrés Pérez', tipo_identificacion: 'CC', numero_identificacion: '1030567890', correo_electronico: 'carlos.perez@email.com', celular: '3109876543', id_departamento: '11', id_ciudad: '11001' });

  const idCli1 = cli1.body?.id_cliente || cli1.body?.id;
  if (idCli1) {
    const sol1 = await run('sol-1', 'POST', '/api/solicitudes', { id_cliente: idCli1, descripcion: 'Análisis fisicoquímico de agua potable', fecha_solicitud: '2024-06-28', estado: 'Pendiente' });
    await run('cli-put', 'PUT', `/api/solicitudes/clientes/${idCli1}`, { nombre_solicitante: 'Universidad Nacional de Colombia', tipo_identificacion: 'NIT', numero_identificacion: '899999063-3', correo_electronico: 'lab.quimica@unal.edu.co', celular: '3001234567', id_departamento: '11', id_ciudad: '11001', tipo_usuario: 'Persona Jurídica' });
  }

  // ── EQUIPOS ──────────────────────────────────────────────────────────────
  console.log('\n[8] EQUIPOS (POST)');
  await run('equipo-1', 'POST', '/api/equipos', { codigo_identificacion: 'EQ-BAL-001', nombre: 'Balanza Analítica', modelo: 'ME204', marca: 'Mettler Toledo', inventario_sena: 'SENA-2023-001', ubicacion: 'Laboratorio Análisis Fisicoquímico', numero_serie: 'B323456789', tipo: 'Medición', clasificacion: 'Analítico', acreditacion: 'SI', sujeto_calibracion: 1, sujeto_verificar: 1, sujeto_calificacion: 0, fecha_adquisicion: '2023-03-01', campo_medicion: '0 - 220 g', exactitud: '0.0001 g', resolucion_division: '0.1 mg', voltaje: '220V', frecuencia: '60 Hz' });
  await run('equipo-2', 'POST', '/api/equipos', { codigo_identificacion: 'EQ-PHM-001', nombre: 'pH-metro', modelo: 'S210', marca: 'Mettler Toledo', inventario_sena: 'SENA-2022-015', ubicacion: 'Laboratorio Aguas', numero_serie: 'K12345678', tipo: 'Medición', clasificacion: 'Electroquímico', acreditacion: 'NO', sujeto_calibracion: 1, sujeto_verificar: 1, sujeto_calificacion: 0, fecha_adquisicion: '2022-08-15', campo_medicion: '0 - 14 pH', exactitud: '±0.01 pH', resolucion_division: '0.001 pH' });

  // ── MATERIALES VOLUMÉTRICOS ──────────────────────────────────────────────
  console.log('\n[9] MATERIALES VOLUMÉTRICOS (POST + PUT)');
  await run('vol-1', 'POST', '/api/volumetricos/materiales', { codigo_id: 'BUR-25-001', nombre_material: 'Bureta 25 mL', volumen_nominal: 25, rango_volumen: '0 - 25 mL', marca: 'BLAUBRAND', resolucion: '0.05 mL', error_max_permitido: '±0.05 mL', modelo: 'Clase A' });
  await run('vol-2', 'POST', '/api/volumetricos/materiales', { codigo_id: 'PIP-10-001', nombre_material: 'Pipeta volumétrica 10 mL', volumen_nominal: 10, rango_volumen: '10 mL', marca: 'BLAUBRAND', resolucion: '0.02 mL', error_max_permitido: '±0.02 mL', modelo: 'Clase A' });
  await run('vol-put', 'PUT', '/api/volumetricos/materiales/BUR-25-001', { nombre_material: 'Bureta 25 mL Clase A', volumen_nominal: 25, rango_volumen: '0 - 25 mL', marca: 'BLAUBRAND', resolucion: '0.05 mL', error_max_permitido: '±0.05 mL', modelo: 'Clase A certificada' });

  // ── MATERIALES REFERENCIA ────────────────────────────────────────────────
  console.log('\n[10] MATERIALES REFERENCIA (POST + PUT)');
  await run('ref-1', 'POST', '/api/referencia/material', { codigo_id: 'REF-TER-001', nombre_material: 'Termómetro de referencia', rango_medicion: '-10 a 110 °C', marca: 'ERTCO', serie: 'T-98765', error_max_permitido: '±0.1 °C', modelo: 'ASTM 63C' });
  await run('ref-2', 'POST', '/api/referencia/material', { codigo_id: 'REF-PES-001', nombre_material: 'Pesa patrón 100 g', rango_medicion: '100 g', marca: 'Mettler Toledo', serie: 'W-44321', error_max_permitido: '±0.05 mg', modelo: 'E2' });
  await run('ref-put', 'PUT', '/api/referencia/material/REF-TER-001', { nombre_material: 'Termómetro de referencia NIST', rango_medicion: '-10 a 110 °C', marca: 'ERTCO', serie: 'T-98765', error_max_permitido: '±0.05 °C', modelo: 'ASTM 63C Trazable NIST' });

  // ── VERIFICACIÓN FINAL GET ───────────────────────────────────────────────
  console.log('\n[11] VERIFICACIÓN — GET después de insertar');
  await run('v-reactivos',   'GET', '/api/reactivos',                   null, [200]);
  await run('v-insumos',     'GET', '/api/insumos',                     null, [200]);
  await run('v-papeleria',   'GET', '/api/papeleria',                   null, [200]);
  await run('v-clientes',    'GET', '/api/solicitudes/clientes',        null, [200]);
  await run('v-solicitudes', 'GET', '/api/solicitudes',                 null, [200]);
  await run('v-equipos',     'GET', '/api/equipos',                     null, [200]);
  await run('v-volumetricos','GET', '/api/volumetricos/materiales',     null, [200]);
  await run('v-referencia',  'GET', '/api/referencia/material',         null, [200]);
  await run('v-dashboard',   'GET', '/api/dashboard/metricas-principales', null, [200]);
  await run('v-logs',        'GET', '/api/logs/acciones',               null, [200]);

  // ── RESUMEN ───────────────────────────────────────────────────────────────
  const ok = results.filter(r => r.pass).length;
  const fail = results.filter(r => !r.pass).length;
  console.log('\n' + '='.repeat(85));
  console.log(`RESULTADO: ${ok} OK  /  ${fail} FALLARON  de ${results.length} operaciones`);
  if (fail > 0) {
    console.log('\nFallaron:');
    results.filter(r => !r.pass).forEach(r => console.log(`  ❌ [${r.status}] ${r.label}`));
  }
  console.log('='.repeat(85));
})();
