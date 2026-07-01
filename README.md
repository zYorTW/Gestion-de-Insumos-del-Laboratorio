# LIBA - Sistema de Gestión de Laboratorio

## Autor
**Yorland Insignares Escorcia**  
Desarrollador Full Stack / Analista de Sistemas

---

## Objetivo del Proyecto
Desarrollar una aplicación web completa para la **gestión de inventario y operaciones de un laboratorio**, permitiendo controlar reactivos, insumos, papelería, equipos, materiales volumétricos, materiales de referencia, solicitudes de clientes y usuarios del sistema, con trazabilidad mediante logs de acciones y generación de reportes.

---

## Descripción del Sistema

El sistema LIBA cubre los siguientes módulos operativos:

| Módulo | Descripción |
|---|---|
| **Reactivos** | Catálogo e inventario de reactivos químicos con control de lotes, fechas de vencimiento, almacenamiento y clasificación |
| **Insumos** | Catálogo e inventario de insumos de laboratorio con control de existencias |
| **Papelería** | Catálogo e inventario de papelería con ajuste de existencias |
| **Equipos** | Fichas técnicas de equipos (HV), historial de mantenimiento e intervalos de calibración |
| **Materiales Volumétricos** | Registro y seguimiento de materiales volumétricos clase A con historial de verificación |
| **Materiales de Referencia** | Registro de patrones y materiales de referencia certificados con historial |
| **Solicitudes y Clientes** | Gestión de clientes y sus solicitudes de servicio |
| **Usuarios** | Administración de usuarios con roles: `Superadmin`, `Admin`, `Auxiliar` |
| **Dashboard** | Métricas principales del laboratorio en tiempo real |
| **Reportes** | Exportación de inventarios a Excel |
| **Logs** | Registro de todas las acciones realizadas en el sistema |

### Roles del sistema
- **Superadmin**: acceso total, incluyendo gestión de usuarios
- **Admin**: acceso a creación, edición y eliminación en todos los módulos
- **Auxiliar**: acceso de solo lectura y ajuste de existencias

---

## Proceso del Proyecto

1. **Diseño de base de datos** — Esquema relacional en TiDB Cloud (MySQL 8.5)
2. **Desarrollo del backend** — API REST en Node.js + Express con autenticación JWT
3. **Desarrollo del frontend** — SPA en Angular 20 con Bootstrap 5 y Lucide Icons
4. **Integración con TiDB Cloud** — Conexión segura vía TLS (puerto 3306) con certificado ISRG Root X1
5. **Validación de endpoints** — 32 endpoints probados (GET, POST, PUT, DELETE, PATCH)
6. **Pruebas de escritura** — Seed de datos reales y validación de operaciones de escritura (40/40 OK)
7. **Alineación de roles** — Corrección de nombres de rol en backend y frontend

---

## Tecnologías utilizadas

**Backend**
- Node.js 24 + Express 4
- mysql2 con SSL/TLS
- jsonwebtoken (JWT)
- bcrypt
- multer (carga de imágenes)
- exceljs (exportación a Excel)
- dotenv

**Frontend**
- Angular 20 (Standalone Components, Signals)
- Bootstrap 5
- Lucide Icons
- TypeScript

**Base de datos**
- TiDB Cloud Serverless (compatible con MySQL 8.5)

---

## Estructura del proyecto

```
Proyecto1/
├── backend/
│   ├── server.js              # Punto de entrada
│   ├── .env.example           # Plantilla de variables de entorno
│   ├── package.json
│   └── src/
│       ├── config/
│       │   ├── db.js          # Pool de conexión con TLS
│       │   └── certs/
│       │       └── isrgrootx1.pem  # Certificado CA para TiDB
│       ├── controllers/       # Lógica de negocio por módulo
│       ├── routes/            # Definición de rutas Express
│       ├── middleware/        # Autenticación JWT, upload
│       └── db/
│           └── seed_and_test.js   # Script de datos semilla + pruebas
└── frontend/
    ├── angular.json
    ├── package.json
    └── src/
        └── app/
            ├── pages/         # Componentes por módulo
            ├── services/      # Servicios HTTP
            └── guards/        # Guards de autenticación y rol
```

---

## Resultados de pruebas

### Endpoints validados: 32/32
| Recurso | GET | POST | PUT/PATCH | DELETE |
|---|:---:|:---:|:---:|:---:|
| Auth / Usuarios | ✅ | ✅ | ✅ | ✅ |
| Reactivos (catálogo + inventario) | ✅ | ✅ | ✅ | ✅ |
| Insumos (catálogo + inventario) | ✅ | ✅ | ✅ | ✅ |
| Papelería (catálogo + inventario) | ✅ | ✅ | ✅ | ✅ |
| Equipos + historial + intervalos | ✅ | ✅ | ✅ | ✅ |
| Volumétricos + historial | ✅ | ✅ | ✅ | — |
| Referencia + historial | ✅ | ✅ | ✅ | ✅ |
| Solicitudes + Clientes | ✅ | ✅ | ✅ | ✅ |
| Dashboard / Reportes / Logs | ✅ | — | — | — |

### Operaciones de escritura: 40/40
Script `seed_and_test.js` corre contra el backend en vivo y valida POST, PUT, DELETE y PATCH en todos los módulos.

---

## Cómo ejecutar el proyecto

### Requisitos previos
- Node.js 18 o superior
- Angular CLI: `npm install -g @angular/cli`
- Cuenta en [TiDB Cloud](https://tidbcloud.com/) con un cluster Serverless y la base de datos `liba_db` creada

### 1. Clonar el repositorio
```bash
git clone https://github.com/tuusuario/liba.git
cd liba
```

### 2. Configurar el backend

```bash
cd backend
npm install
```

Copia el archivo de ejemplo y completa tus credenciales:
```bash
cp .env.example .env
```

Edita `.env` con los datos de tu cluster TiDB:
```
DB_HOST=gateway01.us-east-1.prod.aws.tidbcloud.com
DB_PORT=3306
DB_USER=tu_prefix.root
DB_PASSWORD=tu_password
DB_NAME=liba_db
JWT_SECRET=cualquier-cadena-secreta-larga
```

> **Nota sobre TLS:** La conexión usa el certificado `src/config/certs/isrgrootx1.pem` (ISRG Root X1 de Let's Encrypt, incluido en el repositorio). Si tu red bloquea el puerto 4000 con DPI, usa el puerto 3306 en `DB_PORT` (estándar MySQL, siempre funciona).

Inicia el servidor:
```bash
node server.js
```

El backend queda disponible en `http://localhost:4000`

### 3. Configurar el frontend

```bash
cd ../frontend
npm install
ng serve
```

El frontend queda disponible en `http://localhost:4200`

### 4. Poblar la base de datos con datos de prueba

Con el backend corriendo, ejecuta desde la carpeta `backend/`:
```bash
node src/db/seed_and_test.js
```

Esto inserta datos reales en todos los módulos y valida las 40 operaciones de escritura. El script es **idempotente**: si los datos ya existen, los omite sin error.

### 5. Iniciar sesión

Accede a `http://localhost:4200` e inicia sesión con las credenciales por defecto:

| Rol | Email | Contraseña |
|---|---|---|
| Superadmin | superadmin@gmail.com | 123456 |

---

## Notas técnicas

- **TiDB Serverless** no soporta `AUTO_INCREMENT` en columnas PK de tablas *clustered*. El sistema genera IDs con `SELECT MAX(id) + 1` cuando es necesario.
- El campo de contraseña en la tabla de usuarios es `contrasena` (no `password`).
- El certificado SSL `isrgrootx1.pem` es público (ISRG Root X1) y seguro de incluir en el repositorio.
- Las redes con DPI (inspección profunda de paquetes) pueden bloquear TLS en puertos no estándar (como 4000). Usar el puerto 3306 soluciona este problema.
