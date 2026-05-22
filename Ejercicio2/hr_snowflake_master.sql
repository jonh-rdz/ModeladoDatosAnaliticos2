-- ==============================================================================
-- Archivo: hr_snowflake_master.sql
-- Descripción: Modelo analítico Snowflake Schema
-- Características: Alta Normalización, Trazabilidad, DLP, SP para 1500 registros,
--                  CTEs, Window Functions y Consultas Analíticas.
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS hr_snowflake_analytics;
USE hr_snowflake_analytics;

-- 1. LIMPIEZA SEGURA
DROP PROCEDURE IF EXISTS sp_generar_1500_registros;
DROP VIEW IF EXISTS vw_snowflake_analisis;
DROP TABLE IF EXISTS fact_salarios;
DROP TABLE IF EXISTS dim_empleados;
DROP TABLE IF EXISTS dim_sedes;
DROP TABLE IF EXISTS dim_regiones;
DROP TABLE IF EXISTS dim_puestos;
DROP TABLE IF EXISTS dim_departamentos;
DROP TABLE IF EXISTS dim_tiempo;

-- 2. DDL: DIMENSIONES NORMALIZADAS

-- 2.1. Jerarquía Geográfica: Regiones -> Sedes
CREATE TABLE dim_regiones (
    region_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'PK: Identificador único de región',
    nombre_region VARCHAR(100) NOT NULL UNIQUE COMMENT 'Ej: Norteamérica, LATAM',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Dimensión Nivel 2: Regiones Geográficas Mundiales';

CREATE TABLE dim_sedes (
    sede_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'PK: Identificador de la oficina física',
    region_id INT NOT NULL COMMENT 'FK: Referencia a la región a la que pertenece',
    nombre_sede VARCHAR(100) NOT NULL UNIQUE COMMENT 'Ej: Oficina CDMX, Oficina Madrid',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sede_region FOREIGN KEY (region_id) REFERENCES dim_regiones(region_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Dimensión Nivel 1: Oficinas Físicas';

-- 2.2. Jerarquía Organizacional: Departamentos -> Puestos
CREATE TABLE dim_departamentos (
    departamento_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'PK: Identificador del área',
    nombre_departamento VARCHAR(100) NOT NULL UNIQUE,
    centro_costo VARCHAR(20) NOT NULL COMMENT 'Código financiero para presupuesto',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Dimensión de áreas de negocio';

CREATE TABLE dim_puestos (
    puesto_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'PK: Identificador del cargo',
    nombre_puesto VARCHAR(100) NOT NULL,
    nivel_seniority ENUM('Junior', 'Semi-Senior', 'Senior', 'Lead', 'Manager', 'Director') NOT NULL COMMENT 'Jerarquía del puesto',
    salario_base_referencia DECIMAL(12,2) NOT NULL COMMENT 'Banda salarial usada para el generador de datos',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Dimensión catálogo de cargos y niveles salariales';

-- 2.3. Dimensión Tiempo Conformada
CREATE TABLE dim_tiempo (
    fecha_id INT PRIMARY KEY COMMENT 'PK: Formato YYYYMMDD para optimizar índices en búsquedas por rango',
    fecha DATE NOT NULL,
    anio INT NOT NULL,
    mes INT NOT NULL,
    nombre_mes VARCHAR(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Dimensión Tiempo compartida';

-- 2.4. Dimensión Central de Empleados
CREATE TABLE dim_empleados (
    empleado_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'PK: Id interno del empleado',
    departamento_id INT NOT NULL COMMENT 'FK: Área a la que pertenece',
    puesto_id INT NOT NULL COMMENT 'FK: Cargo que desempeña',
    sede_id INT NOT NULL COMMENT 'FK: Ubicación física donde trabaja',
    nombre_completo VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE COMMENT 'DLP: Prevención de pérdida de datos (Soft Delete)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_emp_depto FOREIGN KEY (departamento_id) REFERENCES dim_departamentos(departamento_id),
    CONSTRAINT fk_emp_puesto FOREIGN KEY (puesto_id) REFERENCES dim_puestos(puesto_id),
    CONSTRAINT fk_emp_sede FOREIGN KEY (sede_id) REFERENCES dim_sedes(sede_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Dimensión principal que orquesta las jerarquías';

-- Índices compuestos para optimizar los múltiples JOINs del Copo de Nieve
CREATE INDEX idx_emp_fk ON dim_empleados(departamento_id, puesto_id, sede_id);

-- 3. DDL: TABLA DE HECHOS
CREATE TABLE fact_salarios (
    salario_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'PK transaccional',
    empleado_id INT NOT NULL COMMENT 'FK hacia la dimensión empleados',
    fecha_id INT NOT NULL COMMENT 'FK hacia la dimensión tiempo',
    salario_bruto DECIMAL(12, 2) NOT NULL CHECK (salario_bruto > 0),
    bono_desempeno DECIMAL(12, 2) DEFAULT 0.00,
    impuestos_retenciones DECIMAL(12, 2) GENERATED ALWAYS AS (salario_bruto * 0.15) STORED COMMENT 'Retención fiscal fija 15%',
    salario_neto DECIMAL(12, 2) GENERATED ALWAYS AS (salario_bruto + bono_desempeno - (salario_bruto * 0.15)) STORED COMMENT 'Métrica física calculada',
    
    CONSTRAINT fk_fact_emp FOREIGN KEY (empleado_id) REFERENCES dim_empleados(empleado_id) ON DELETE RESTRICT,
    CONSTRAINT fk_fact_tiempo FOREIGN KEY (fecha_id) REFERENCES dim_tiempo(fecha_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Hechos: Transacciones salariales mensuales';

CREATE INDEX idx_fact_metrics ON fact_salarios(empleado_id, fecha_id);

-- 4. DML: INSERCIÓN DE CATÁLOGOS BASE

INSERT INTO dim_regiones (nombre_region) VALUES ('Norteamérica'), ('Latinoamérica'), ('Europa');

INSERT INTO dim_sedes (region_id, nombre_sede) VALUES 
(1, 'Oficina Nueva York'), (1, 'Oficina Toronto'), 
(2, 'Oficina CDMX'), (2, 'Oficina Bogotá'), 
(3, 'Oficina Madrid');

INSERT INTO dim_departamentos (nombre_departamento, centro_costo) VALUES 
('Ingeniería de Datos', 'C-100'), ('Ventas Corporativas', 'C-200'), 
('Finanzas', 'C-300'), ('Talento Humano', 'C-400');

INSERT INTO dim_puestos (nombre_puesto, nivel_seniority, salario_base_referencia) VALUES 
('Data Engineer', 'Semi-Senior', 4500.00), ('Account Executive', 'Senior', 3500.00), 
('Analista Financiero', 'Junior', 2000.00), ('HR Business Partner', 'Lead', 5500.00), 
('Director Regional', 'Director', 9500.00);

INSERT INTO dim_tiempo (fecha_id, fecha, anio, mes, nombre_mes) VALUES 
(20260531, '2026-05-31', 2026, 5, 'Mayo');

-- Insertamos 5 Empleados y Salarios Semilla (Base para el generador masivo)
INSERT INTO dim_empleados (departamento_id, puesto_id, sede_id, nombre_completo, email) VALUES
(1, 1, 3, 'Carlos Mendoza', 'carlos.mendoza@empresa.com'),
(2, 2, 1, 'Laura Pineda', 'laura.pineda@empresa.com'),
(3, 3, 4, 'Andrés Vargas', 'andres.vargas@empresa.com'),
(4, 4, 5, 'Elena Castro', 'elena.castro@empresa.com'),
(2, 5, 2, 'Fernando Gil', 'fernando.gil@empresa.com');

INSERT INTO fact_salarios (empleado_id, fecha_id, salario_bruto, bono_desempeno) VALUES
(1, 20260531, 4600.00, 300.00),
(2, 20260531, 3600.00, 500.00),
(3, 20260531, 2100.00, 0.00),
(4, 20260531, 5600.00, 400.00),
(5, 20260531, 9800.00, 1200.00);

-- 5. PROCEDIMIENTO ALMACENADO PARA GENERAR 1500 REGISTROS
DELIMITER //
CREATE PROCEDURE sp_generar_1500_registros()
BEGIN
    DECLARE v_total INT;
    DECLARE v_depto INT;
    DECLARE v_puesto INT;
    DECLARE v_sede INT;
    DECLARE v_salario_ref DECIMAL(12,2);
    
    -- Verificamos cuántos hay actualmente
    SELECT COUNT(*) INTO v_total FROM dim_empleados;
    
    WHILE v_total < 1500 DO
        -- Generamos llaves foráneas aleatorias válidas
        SET v_depto = FLOOR(1 + (RAND() * 4));
        SET v_puesto = FLOOR(1 + (RAND() * 5));
        SET v_sede = FLOOR(1 + (RAND() * 5));
        
        -- Insertamos el Empleado
        INSERT INTO dim_empleados (departamento_id, puesto_id, sede_id, nombre_completo, email)
        VALUES (
            v_depto, v_puesto, v_sede,
            CONCAT('Empleado Simulado ', v_total + 1),
            CONCAT('user_', v_total + 1, '@empresa.com')
        );
        
        -- Buscamos el salario de referencia del puesto asignado
        SELECT salario_base_referencia INTO v_salario_ref FROM dim_puestos WHERE puesto_id = v_puesto;
        
        -- Insertamos la Nómina (Salario con variación aleatoria del +/- 15%)
        INSERT INTO fact_salarios (empleado_id, fecha_id, salario_bruto, bono_desempeno)
        VALUES (
            LAST_INSERT_ID(),
            20260531,
            v_salario_ref * (0.85 + (RAND() * 0.30)), -- Variación del salario base
            v_salario_ref * (RAND() * 0.15)           -- Bono de 0% a 15%
        );
        
        SET v_total = v_total + 1;
    END WHILE;
END //
DELIMITER ;

-- Ejecutamos el SP y MySQL genera los 1500 registros con integridad referencial
CALL sp_generar_1500_registros();

-- 6. CAPA DE PRESENTACIÓN: VISTA CON CTEs Y WINDOW FUNCTIONS
CREATE OR REPLACE VIEW vw_snowflake_analisis AS
-- CTE: Desnormalizamos el Copo de Nieve
WITH DatosAplanados AS (
    SELECT 
        f.salario_id,
        e.empleado_id,
        e.nombre_completo,
        r.nombre_region,
        s.nombre_sede,
        d.nombre_departamento,
        p.nombre_puesto,
        p.nivel_seniority,
        f.salario_bruto,
        f.salario_neto
    FROM fact_salarios f
    INNER JOIN dim_empleados e ON f.empleado_id = e.empleado_id
    INNER JOIN dim_sedes s ON e.sede_id = s.sede_id
    INNER JOIN dim_regiones r ON s.region_id = r.region_id
    INNER JOIN dim_departamentos d ON e.departamento_id = d.departamento_id
    INNER JOIN dim_puestos p ON e.puesto_id = p.puesto_id
    WHERE e.is_active = TRUE
)
-- Aplicación de Window Functions Analíticas sobre el CTE
SELECT 
    da.*,
    
    -- Window Function 1: Ranking salarial dentro de cada Región
    RANK() OVER (
        PARTITION BY da.nombre_region 
        ORDER BY da.salario_neto DESC
    ) AS ranking_en_region,
    
    -- Window Function 2: Salario Promedio por Puesto
    ROUND(AVG(da.salario_neto) OVER (
        PARTITION BY da.nombre_puesto
    ), 2) AS promedio_de_su_puesto,
    
    -- Window Function 3: Diferencia contra el promedio de su cargo
    ROUND(da.salario_neto - AVG(da.salario_neto) OVER (PARTITION BY da.nombre_puesto), 2) AS diff_vs_promedio_puesto
    
FROM DatosAplanados da;

-- 7. CONSULTAS ANALÍTICAS DIRECTAS EN BD

-- KPI A: Validación de la cantidad de registros generados (+1500)
SELECT COUNT(*) AS total_nóminas_procesadas FROM vw_snowflake_analisis;

-- KPI B: Salarios por Región
SELECT 
    nombre_region,
    COUNT(empleado_id) AS total_empleados,
    ROUND(SUM(salario_neto), 2) AS gasto_salarial_total,
    ROUND(AVG(salario_neto), 2) AS salario_promedio
FROM vw_snowflake_analisis
GROUP BY nombre_region
ORDER BY gasto_salarial_total DESC;

-- KPI C: Auditoría de Brecha Salarial
-- ¿Qué empleados ganan por debajo del promedio estándar de su puesto?
SELECT 
    nombre_completo,
    nombre_puesto,
    nombre_region,
    salario_neto,
    promedio_de_su_puesto,
    diff_vs_promedio_puesto AS deficit_salarial
FROM vw_snowflake_analisis
WHERE diff_vs_promedio_puesto < -500 -- Ganan $500 menos que la media de su puesto
ORDER BY deficit_salarial ASC
LIMIT 10;

-- KPI D: Top 10 Empleados con Mayor Salario
SELECT 
    nombre_completo,
    nombre_puesto,
    nombre_departamento,
    nombre_sede,
    salario_neto
FROM vw_snowflake_analisis
WHERE ranking_en_region <= 3 -- Extraemos el Top 3 de CADA región usando el RANK()
ORDER BY salario_neto DESC
LIMIT 10;