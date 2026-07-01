-- ============================================================
--  BASE DE DATOS COMPLETA  -  Sistema de Gestión de Laboratorio
--  Reconstruida desde el código fuente (controllers + rutas)
--  Base: lab  |  Motor: InnoDB  |  Compatible: MySQL / TiDB
-- ============================================================

CREATE DATABASE IF NOT EXISTS liba_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE liba_db;

-- ============================================================
--  AUTENTICACIÓN
-- ============================================================

CREATE TABLE IF NOT EXISTS roles (
    id_rol    INT         AUTO_INCREMENT PRIMARY KEY,
    nombre    VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario  INT          AUTO_INCREMENT PRIMARY KEY,
    email       VARCHAR(100) UNIQUE NOT NULL,
    contrasena  VARCHAR(255) NOT NULL,
    rol_id      INT          NOT NULL,
    estado      ENUM('ACTIVO','INACTIVO') DEFAULT 'ACTIVO',
    created_at  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (rol_id) REFERENCES roles(id_rol) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
--  AUDITORÍA
-- ============================================================

CREATE TABLE IF NOT EXISTS logs_acciones (
    id          INT          AUTO_INCREMENT PRIMARY KEY,
    usuario_id  INT,
    accion      VARCHAR(100) NOT NULL,
    modulo      VARCHAR(100) NOT NULL,
    descripcion TEXT,
    fecha       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_log_usuario (usuario_id),
    INDEX idx_log_modulo  (modulo),
    INDEX idx_log_fecha   (fecha),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id_usuario) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS movimientos_inventario (
    id                  INT          AUTO_INCREMENT PRIMARY KEY,
    usuario_id          INT,
    producto_tipo       VARCHAR(50)  NOT NULL,        -- REACTIVO | INSUMO | PAPELERIA
    producto_referencia VARCHAR(100),                 -- lote o id del producto
    tipo_movimiento     VARCHAR(50)  NOT NULL,        -- ENTRADA | SALIDA | AJUSTE
    cantidad            DECIMAL(12,3),
    fecha               TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    observacion         TEXT,
    INDEX idx_mov_tipo_fecha    (producto_tipo, fecha),
    INDEX idx_mov_usuario_fecha (usuario_id, fecha),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id_usuario) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
--  REACTIVOS  -  Tablas de catálogo / lookup
-- ============================================================

CREATE TABLE IF NOT EXISTS tipo_reactivo (
    id     INT         AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS clasificacion_sga (
    id     INT          AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS unidades (
    id     INT         AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS estado_fisico (
    id     INT         AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tipo_recipiente (
    id     INT         AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS almacenamiento (
    id     INT          AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL
) ENGINE=InnoDB;

-- Catálogo maestro de reactivos
CREATE TABLE IF NOT EXISTS catalogo_reactivos (
    codigo               VARCHAR(10)  PRIMARY KEY,
    nombre               VARCHAR(200) NOT NULL,
    tipo_reactivo        VARCHAR(50)  NOT NULL,
    clasificacion_sga    VARCHAR(100) NOT NULL,
    descripcion          TEXT,
    fecha_creacion       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Inventario de reactivos (por lote)
CREATE TABLE IF NOT EXISTS reactivos (
    lote                VARCHAR(30)    PRIMARY KEY,
    codigo              VARCHAR(10)    NOT NULL,
    nombre              VARCHAR(200)   NOT NULL,
    marca               VARCHAR(50)    NOT NULL,
    referencia          VARCHAR(100),
    cas                 VARCHAR(50),
    presentacion        DECIMAL(10,2)  NOT NULL,
    presentacion_cant   DECIMAL(10,2)  NOT NULL,
    cantidad_total      DECIMAL(10,2)  NOT NULL,
    fecha_adquisicion   DATE           NOT NULL,
    fecha_vencimiento   DATE           NOT NULL,
    observaciones       TEXT,
    fecha_creacion      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    tipo_id             INT NOT NULL,
    clasificacion_id    INT NOT NULL,
    unidad_id           INT NOT NULL,
    estado_id           INT NOT NULL,
    almacenamiento_id   INT NOT NULL,
    tipo_recipiente_id  INT NOT NULL,
    UNIQUE (codigo, lote),
    FOREIGN KEY (codigo)             REFERENCES catalogo_reactivos(codigo),
    FOREIGN KEY (tipo_id)            REFERENCES tipo_reactivo(id),
    FOREIGN KEY (clasificacion_id)   REFERENCES clasificacion_sga(id),
    FOREIGN KEY (unidad_id)          REFERENCES unidades(id),
    FOREIGN KEY (estado_id)          REFERENCES estado_fisico(id),
    FOREIGN KEY (almacenamiento_id)  REFERENCES almacenamiento(id),
    FOREIGN KEY (tipo_recipiente_id) REFERENCES tipo_recipiente(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS hoja_seguridad (
    id             INT          AUTO_INCREMENT PRIMARY KEY,
    lote           VARCHAR(30)  NOT NULL UNIQUE,
    hoja_seguridad VARCHAR(255) NOT NULL,
    fecha_subida   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    contenido_pdf  LONGBLOB,
    FOREIGN KEY (lote) REFERENCES reactivos(lote) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS cert_analisis (
    id                   INT          AUTO_INCREMENT PRIMARY KEY,
    lote                 VARCHAR(30)  NOT NULL UNIQUE,
    certificado_analisis VARCHAR(255) NOT NULL,
    fecha_subida         TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    contenido_pdf        LONGBLOB,
    FOREIGN KEY (lote) REFERENCES reactivos(lote) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
--  INSUMOS
-- ============================================================

CREATE TABLE IF NOT EXISTS catalogo_insumos (
    item        INT          PRIMARY KEY,
    nombre      VARCHAR(200) NOT NULL,
    descripcion TEXT,
    imagen      MEDIUMBLOB
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS insumos (
    id                  INT          AUTO_INCREMENT PRIMARY KEY,
    item_catalogo       INT          NOT NULL,
    nombre              VARCHAR(100) NOT NULL,
    cantidad_adquirida  INT          NOT NULL,
    cantidad_existente  INT          NOT NULL,
    presentacion        VARCHAR(50),
    marca               VARCHAR(100),
    referencia          VARCHAR(20),
    descripcion         TEXT,
    fecha_adquisicion   DATE,
    ubicacion           VARCHAR(100),
    observaciones       TEXT,
    FOREIGN KEY (item_catalogo) REFERENCES catalogo_insumos(item)
) ENGINE=InnoDB;

-- ============================================================
--  PAPELERÍA
-- ============================================================

CREATE TABLE IF NOT EXISTS catalogo_papeleria (
    item        INT          PRIMARY KEY,
    nombre      VARCHAR(200) NOT NULL,
    descripcion TEXT,
    imagen      MEDIUMBLOB
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS papeleria (
    id                  INT          AUTO_INCREMENT PRIMARY KEY,
    item_catalogo       INT          NOT NULL,
    nombre              VARCHAR(100) NOT NULL,
    cantidad_adquirida  INT          NOT NULL,
    cantidad_existente  INT          NOT NULL,
    presentacion        ENUM('unidad','paquete','caja','cajas') NOT NULL,
    marca               VARCHAR(100),
    descripcion         TEXT,
    fecha_adquisicion   DATE,
    ubicacion           VARCHAR(100),
    observaciones       TEXT,
    FOREIGN KEY (item_catalogo) REFERENCES catalogo_papeleria(item)
) ENGINE=InnoDB;

-- ============================================================
--  SOLICITUDES  -  Clientes colombianos
-- ============================================================

CREATE TABLE IF NOT EXISTS departamentos (
    codigo VARCHAR(10)  PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ciudades (
    codigo               VARCHAR(10)  PRIMARY KEY,
    nombre               VARCHAR(100) NOT NULL,
    codigo_departamento  VARCHAR(10)  NOT NULL,
    FOREIGN KEY (codigo_departamento) REFERENCES departamentos(codigo)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS clientes (
    id_cliente              INT          AUTO_INCREMENT PRIMARY KEY,
    numero                  INT          NOT NULL UNIQUE,
    fecha_vinculacion       DATE         NOT NULL,
    tipo_usuario            ENUM('Emprendedor','Persona Natural','Persona Jurídica','Aprendiz SENA','Instructor SENA','Centros SENA') NOT NULL,
    razon_social            VARCHAR(255),
    nit                     VARCHAR(50),
    nombre_solicitante      VARCHAR(255) NOT NULL,
    tipo_identificacion     ENUM('CC','TI','CE','NIT','PASAPORTE','OTRO') NOT NULL,
    numero_identificacion   VARCHAR(50)  NOT NULL UNIQUE,
    sexo                    ENUM('M','F','Otro') NOT NULL,
    tipo_poblacion          VARCHAR(100),
    direccion               VARCHAR(255),
    id_ciudad               VARCHAR(10),
    id_departamento         VARCHAR(10),
    celular                 VARCHAR(20),
    telefono                VARCHAR(20),
    correo_electronico      VARCHAR(255),
    tipo_vinculacion        VARCHAR(100),
    registro_realizado_por  VARCHAR(255),
    observaciones           TEXT,
    activo                  BOOLEAN   DEFAULT TRUE,
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_ciudad)       REFERENCES ciudades(codigo)       ON DELETE RESTRICT,
    FOREIGN KEY (id_departamento) REFERENCES departamentos(codigo)  ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Solicitudes (
    solicitud_id            INT          NOT NULL PRIMARY KEY,
    id_cliente              INT          NOT NULL,
    tipo_solicitud          VARCHAR(100),
    nombre_muestra          VARCHAR(255),
    fecha_solicitud         DATE,
    lote_producto           VARCHAR(100),
    fecha_vencimiento_muestra DATE,
    tipo_muestra            VARCHAR(100),
    tipo_empaque            VARCHAR(100),
    analisis_requerido      VARCHAR(255),
    req_analisis            BOOLEAN,
    cant_muestras           INT,
    solicitud_recibida      VARCHAR(255),
    fecha_entrega_muestra   DATE,
    recibe_personal         VARCHAR(255),
    cargo_personal          VARCHAR(100),
    observaciones           TEXT,
    fecha_creacion          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS oferta (
    id_oferta                   INT  AUTO_INCREMENT PRIMARY KEY,
    id_solicitud                INT,
    genero_cotizacion           BOOLEAN,
    valor_cotizacion            DECIMAL(15,2),
    fecha_envio_oferta          DATE,
    realizo_seguimiento_oferta  BOOLEAN,
    observacion_oferta          TEXT,
    FOREIGN KEY (id_solicitud) REFERENCES Solicitudes(solicitud_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS revision_oferta (
    id_revision             INT  AUTO_INCREMENT PRIMARY KEY,
    id_solicitud            INT,
    fecha_limite_entrega    DATE,
    fecha_envio_resultados  DATE,
    servicio_es_viable      BOOLEAN,
    FOREIGN KEY (id_solicitud) REFERENCES Solicitudes(solicitud_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS seguimiento_encuesta (
    id_encuesta             INT  AUTO_INCREMENT PRIMARY KEY,
    id_solicitud            INT,
    fecha_encuesta          DATE,
    comentarios             TEXT,
    recomendaria_servicio   BOOLEAN,
    cliente_respondio       BOOLEAN,
    solicito_nueva_encuesta BOOLEAN,
    FOREIGN KEY (id_solicitud) REFERENCES Solicitudes(solicitud_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
--  EQUIPOS  -  Hoja de Vida (HV)
-- ============================================================

CREATE TABLE IF NOT EXISTS hv_equipos (
    codigo_identificacion   VARCHAR(50)  PRIMARY KEY,
    nombre                  VARCHAR(200),
    modelo                  VARCHAR(100),
    marca                   VARCHAR(100),
    inventario_sena         VARCHAR(100),
    ubicacion               VARCHAR(100),
    acreditacion            VARCHAR(100),
    tipo_manual             VARCHAR(50),
    numero_serie            VARCHAR(100),
    tipo                    VARCHAR(100),
    clasificacion           VARCHAR(100),
    manual_usuario          TEXT,
    puesta_en_servicio      DATE,
    fecha_adquisicion       DATE,
    requerimientos_equipo   TEXT,
    elementos_electricos    TEXT,
    voltaje                 VARCHAR(50),
    elementos_mecanicos     TEXT,
    frecuencia              VARCHAR(50),
    campo_medicion          VARCHAR(100),
    exactitud               VARCHAR(100),
    sujeto_verificar        BOOLEAN,
    sujeto_calibracion      BOOLEAN,
    resolucion_division     VARCHAR(100),
    sujeto_calificacion     BOOLEAN,
    accesorios              TEXT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ficha_tecnica_de_equipos (
    id                              INT  AUTO_INCREMENT PRIMARY KEY,
    codigo_identificador            VARCHAR(50)   NOT NULL,
    nombre                          VARCHAR(200),
    marca                           VARCHAR(100),
    modelo                          VARCHAR(100),
    serie                           VARCHAR(100),
    fabricante                      VARCHAR(100),
    fecha_adq                       DATE,
    uso                             TEXT,
    fecha_func                      DATE,
    precio                          DECIMAL(15,2),
    accesorios                      TEXT,
    manual_ope                      VARCHAR(100),
    idioma_manual                   VARCHAR(50),
    magnitud                        VARCHAR(100),
    resolucion                      VARCHAR(100),
    precision_med                   VARCHAR(100),
    exactitud                       VARCHAR(100),
    rango_de_medicion               VARCHAR(100),
    rango_de_uso                    VARCHAR(100),
    voltaje                         VARCHAR(50),
    potencia                        VARCHAR(50),
    amperaje                        VARCHAR(50),
    frecuencia                      VARCHAR(50),
    ancho                           DECIMAL(10,2),
    alto                            DECIMAL(10,2),
    peso_kg                         DECIMAL(10,2),
    profundidad                     DECIMAL(10,2),
    temperatura_c                   VARCHAR(50),
    humedad_porcentaje              VARCHAR(50),
    limitaciones_e_interferencias   TEXT,
    otros                           TEXT,
    especificaciones_software       TEXT,
    proveedor                       VARCHAR(150),
    email                           VARCHAR(100),
    telefono                        VARCHAR(50),
    fecha_de_instalacion            DATE,
    alcance_del_servicio            TEXT,
    garantia                        VARCHAR(100),
    observaciones                   TEXT,
    recibido_por                    VARCHAR(100),
    cargo_y_firma                   MEDIUMBLOB,
    fecha                           DATE,
    FOREIGN KEY (codigo_identificador) REFERENCES hv_equipos(codigo_identificacion) ON DELETE CASCADE
) ENGINE=InnoDB;

-- PK compuesta por equipo + consecutivo (migración aplicada)
CREATE TABLE IF NOT EXISTS historial_hv (
    equipo_id           VARCHAR(50)    NOT NULL,
    consecutivo         INT            NOT NULL,
    fecha               DATE,
    tipo_historial      VARCHAR(100),
    codigo_registro     VARCHAR(100),
    tolerancia_g        DECIMAL(10,4),
    tolerancia_error_g  DECIMAL(10,4),
    incertidumbre_u     DECIMAL(10,4),
    realizo             VARCHAR(100),
    superviso           VARCHAR(100),
    observaciones       TEXT,
    PRIMARY KEY (equipo_id, consecutivo),
    FOREIGN KEY (equipo_id) REFERENCES hv_equipos(codigo_identificacion) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS intervalo_hv (
    equipo_id                       VARCHAR(50)   NOT NULL,
    consecutivo                     INT           NOT NULL,
    unidad_nominal_g                DECIMAL(10,4),
    calibracion_1                   DECIMAL(10,4),
    fecha_c1                        DATE,
    error_c1_g                      DECIMAL(10,4),
    calibracion_2                   DECIMAL(10,4),
    fecha_c2                        DATE,
    error_c2_g                      DECIMAL(10,4),
    diferencia_dias                 INT,
    desviacion                      DECIMAL(10,6),
    deriva                          DECIMAL(10,6),
    tolerancia_g                    DECIMAL(10,4),
    intervalo_calibraciones_dias    INT,
    intervalo_calibraciones_anios   DECIMAL(5,2),
    PRIMARY KEY (equipo_id, consecutivo),
    FOREIGN KEY (equipo_id) REFERENCES hv_equipos(codigo_identificacion) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
--  MATERIAL VOLUMÉTRICO
-- ============================================================

CREATE TABLE IF NOT EXISTS material_volumetrico (
    codigo_id           VARCHAR(50)   PRIMARY KEY,
    nombre_material     VARCHAR(200)  NOT NULL,
    volumen_nominal     DECIMAL(10,3),
    rango_volumen       VARCHAR(100),
    marca               VARCHAR(100),
    resolucion          VARCHAR(100),
    error_max_permitido VARCHAR(100),
    modelo              VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS historial_volumetrico (
    consecutivo                 INT          NOT NULL,
    codigo_material             VARCHAR(50)  NOT NULL,
    fecha                       DATE,
    tipo_historial_instrumento  VARCHAR(100),
    codigo_registro             VARCHAR(100),
    realizo                     VARCHAR(100),
    superviso                   VARCHAR(100),
    PRIMARY KEY (codigo_material, consecutivo),
    FOREIGN KEY (codigo_material) REFERENCES material_volumetrico(codigo_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS intervalo_volumetrico (
    consecutivo                 INT          NOT NULL,
    codigo_material             VARCHAR(50)  NOT NULL,
    valor_nominal               DECIMAL(10,4),
    fecha_c1                    DATE,
    error_c1                    DECIMAL(10,6),
    fecha_c2                    DATE,
    error_c2                    DECIMAL(10,6),
    diferencia_tiempo_dias      INT,
    desviacion_abs              DECIMAL(10,6),
    deriva                      DECIMAL(10,6),
    tolerancia                  DECIMAL(10,6),
    intervalo_calibracion_dias  INT,
    intervalo_calibracion_anos  DECIMAL(5,2),
    incertidumbre_exp           DECIMAL(10,6),
    PRIMARY KEY (codigo_material, consecutivo),
    FOREIGN KEY (codigo_material) REFERENCES material_volumetrico(codigo_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
--  MATERIAL DE REFERENCIA
-- ============================================================

CREATE TABLE IF NOT EXISTS material_referencia (
    codigo_id           VARCHAR(50)   PRIMARY KEY,
    nombre_material     VARCHAR(200)  NOT NULL,
    rango_medicion      VARCHAR(100),
    marca               VARCHAR(100),
    serie               VARCHAR(100),
    error_max_permitido VARCHAR(100),
    modelo              VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS historial_referencia (
    consecutivo                 INT          NOT NULL,
    codigo_material             VARCHAR(50)  NOT NULL,
    fecha                       DATE,
    tipo_historial_instrumento  VARCHAR(100),
    codigo_registro             VARCHAR(100),
    realizo                     VARCHAR(100),
    superviso                   VARCHAR(100),
    PRIMARY KEY (codigo_material, consecutivo),
    FOREIGN KEY (codigo_material) REFERENCES material_referencia(codigo_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS intervalo_referencia (
    consecutivo                 INT          NOT NULL,
    codigo_material             VARCHAR(50)  NOT NULL,
    valor_nominal               DECIMAL(10,4),
    fecha_c1                    DATE,
    error_c1                    DECIMAL(10,6),
    fecha_c2                    DATE,
    error_c2                    DECIMAL(10,6),
    diferencia_tiempo_dias      INT,
    desviacion_abs              DECIMAL(10,6),
    deriva                      DECIMAL(10,6),
    tolerancia                  DECIMAL(10,6),
    intervalo_calibracion_dias  INT,
    intervalo_calibracion_anos  DECIMAL(5,2),
    incertidumbre_exp           DECIMAL(10,6),
    PRIMARY KEY (codigo_material, consecutivo),
    FOREIGN KEY (codigo_material) REFERENCES material_referencia(codigo_id) ON DELETE CASCADE
) ENGINE=InnoDB;


-- ============================================================
--  DATOS SEMILLA
-- ============================================================

-- Roles
INSERT IGNORE INTO roles (nombre) VALUES
    ('Superadmin'),
    ('Admin'),
    ('Auxiliar');

-- Usuarios de prueba  (contraseña: 123456)
INSERT IGNORE INTO usuarios (email, contrasena, rol_id, estado) VALUES
    ('superadmin@gmail.com', '$2b$10$DAKA3pW./pGwJoG0PUwQB.oYm6lC/3oYU32pU0RBnag3JcE0Umj3C', 1, 'ACTIVO'),
    ('admin@gmail.com',      '$2b$10$DAKA3pW./pGwJoG0PUwQB.oYm6lC/3oYU32pU0RBnag3JcE0Umj3C', 2, 'ACTIVO'),
    ('auxiliar@gmail.com',   '$2b$10$DAKA3pW./pGwJoG0PUwQB.oYm6lC/3oYU32pU0RBnag3JcE0Umj3C', 3, 'ACTIVO');

-- Catálogos de reactivos
INSERT IGNORE INTO tipo_reactivo (nombre) VALUES ('Controlado'), ('No controlado');

INSERT IGNORE INTO clasificacion_sga (nombre) VALUES
    ('Irritación cutánea y otros'),
    ('Inflamables'),
    ('Corrosivo'),
    ('Peligro para la respiración'),
    ('No peligro'),
    ('Tóxico'),
    ('Peligro para el medio ambiente'),
    ('Comburente');

INSERT IGNORE INTO unidades (nombre) VALUES
    ('mL'), ('g'), ('uL'), ('nmol'), ('umol'), ('mg'), ('Unidad');

INSERT IGNORE INTO estado_fisico (nombre) VALUES
    ('Liquido'), ('Solido'), ('Viscoso'), ('Gas');

INSERT IGNORE INTO tipo_recipiente (nombre) VALUES
    ('Vidrio'), ('Plástico'), ('Metalico');

INSERT IGNORE INTO almacenamiento (nombre) VALUES
    ('No aplica'),
    ('Nevera Quimica- Nivel 1'), ('Nevera Quimica- Nivel 2'), ('Nevera Quimica- Nivel 3'),
    ('Nevera Quimica- Nivel 4'), ('Nevera Quimica- Nivel 5'), ('Nevera Quimica- Nivel 6'),
    ('Nevera Quimica (Puerta)'),
    ('Nevera MB- Puerta Izquierda'), ('Nevera MB- Medios Liquidos'),
    ('Nevera MB- Puerta Derecha N2'), ('Nevera MB- Puerta Derecha N4'), ('Nevera MB-API'),
    ('Gabinete Amarillo- Nivel 1'), ('Gabinete Amarillo- Nivel 2'),
    ('Gabinete Amarillo- Nivel 3'), ('Gabinete Amarillo- Nivel 4'),
    ('Gabinete Azul- Nivel 1'), ('Gabinete Azul- Nivel 2'), ('Gabinete Azul- Nivel 3'),
    ('Gabinete Azul- Nivel 4'), ('Gabinete Azul- Nivel 5'),
    ('Estanteria B3- Nivel 1'), ('Estanteria B3- Nivel 2'), ('Estanteria B3- Nivel 3'),
    ('Estanteria B3- Nivel 4'), ('Estanteria B3- Nivel 5'),
    ('Estanteria D1- Nivel 1'), ('Estanteria D1- Nivel 2'), ('Estanteria D1- Nivel 3'),
    ('Estanteria D1- Nivel 4'), ('Estanteria D1- Nivel 5');

-- Departamentos y ciudades de Colombia (principales)
INSERT IGNORE INTO departamentos (codigo, nombre) VALUES
    ('05', 'Antioquia'),
    ('08', 'Atlántico'),
    ('11', 'Bogotá D.C.'),
    ('13', 'Bolívar'),
    ('15', 'Boyacá'),
    ('17', 'Caldas'),
    ('18', 'Caquetá'),
    ('19', 'Cauca'),
    ('20', 'Cesar'),
    ('23', 'Córdoba'),
    ('25', 'Cundinamarca'),
    ('27', 'Chocó'),
    ('41', 'Huila'),
    ('44', 'La Guajira'),
    ('47', 'Magdalena'),
    ('50', 'Meta'),
    ('52', 'Nariño'),
    ('54', 'Norte de Santander'),
    ('63', 'Quindío'),
    ('66', 'Risaralda'),
    ('68', 'Santander'),
    ('70', 'Sucre'),
    ('73', 'Tolima'),
    ('76', 'Valle del Cauca'),
    ('81', 'Arauca'),
    ('85', 'Casanare'),
    ('86', 'Putumayo'),
    ('88', 'San Andrés y Providencia'),
    ('91', 'Amazonas'),
    ('94', 'Guainía'),
    ('95', 'Guaviare'),
    ('97', 'Vaupés'),
    ('99', 'Vichada');

INSERT IGNORE INTO ciudades (codigo, nombre, codigo_departamento) VALUES
    -- Antioquia
    ('05001', 'Medellín',        '05'),
    ('05088', 'Bello',           '05'),
    ('05376', 'Itagüí',          '05'),
    ('05615', 'Rionegro',        '05'),
    -- Atlántico
    ('08001', 'Barranquilla',    '08'),
    ('08078', 'Baranoa',         '08'),
    -- Bogotá
    ('11001', 'Bogotá',          '11'),
    -- Bolívar
    ('13001', 'Cartagena',       '13'),
    -- Boyacá
    ('15001', 'Tunja',           '15'),
    -- Caldas
    ('17001', 'Manizales',       '17'),
    -- Cauca
    ('19001', 'Popayán',         '19'),
    -- Cesar
    ('20001', 'Valledupar',      '20'),
    -- Córdoba
    ('23001', 'Montería',        '23'),
    -- Cundinamarca
    ('25175', 'Chía',            '25'),
    ('25754', 'Soacha',          '25'),
    -- Huila
    ('41001', 'Neiva',           '41'),
    -- Magdalena
    ('47001', 'Santa Marta',     '47'),
    -- Meta
    ('50001', 'Villavicencio',   '50'),
    -- Nariño
    ('52001', 'Pasto',           '52'),
    -- Norte de Santander
    ('54001', 'Cúcuta',          '54'),
    -- Quindío
    ('63001', 'Armenia',         '63'),
    -- Risaralda
    ('66001', 'Pereira',         '66'),
    ('66170', 'Dosquebradas',    '66'),
    -- Santander
    ('68001', 'Bucaramanga',     '68'),
    ('68081', 'Barrancabermeja', '68'),
    -- Sucre
    ('70001', 'Sincelejo',       '70'),
    -- Tolima
    ('73001', 'Ibagué',          '73'),
    -- Valle del Cauca
    ('76001', 'Cali',            '76'),
    ('76109', 'Buenaventura',    '76'),
    ('76520', 'Palmira',         '76'),
    ('76111', 'Buga',            '76'),
    ('76147', 'Cartago',         '76'),
    ('76054', 'Tuluá',           '76'),
    ('76122', 'Candelaria',      '76'),
    ('76364', 'Jamundí',         '76'),
    ('76246', 'El Cerrito',      '76'),
    ('76400', 'La Unión',        '76'),
    ('76497', 'Pradera',         '76'),
    ('76563', 'Roldanillo',      '76'),
    ('76606', 'Riofrío',         '76'),
    ('76670', 'San Pedro',       '76'),
    ('76736', 'Sevilla',         '76'),
    ('76763', 'Trujillo',        '76'),
    ('76828', 'Vijes',           '76'),
    ('76845', 'Yotoco',          '76'),
    ('76863', 'Yumbo',           '76'),
    ('76869', 'Zarzal',          '76');
