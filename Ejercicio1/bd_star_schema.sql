-- 1. CREACIÓN DE LA BASE DE DATOS
CREATE DATABASE IF NOT EXISTS star_schema;
USE star_schema;

-- 2. CREACIÓN DE TABLAS DIMENSIÓN

-- Dimensión: Empleados
CREATE TABLE DIM_EMPLEADOS (
    empleado_key INT AUTO_INCREMENT PRIMARY KEY,
    dui VARCHAR(10) NOT NULL UNIQUE,                -- Formato El Salvador: 00000000-0
    nombre_completo VARCHAR(100) NOT NULL,
    genero VARCHAR(15) NOT NULL,
    puesto_cargo VARCHAR(50) NOT NULL
) ENGINE=InnoDB;

-- Dimensión: Departamentos
CREATE TABLE DIM_DEPARTAMENTOS (
    departamento_key INT AUTO_INCREMENT PRIMARY KEY,
    nombre_departamento VARCHAR(50) NOT NULL
) ENGINE=InnoDB;

-- Dimensión: Sedes
CREATE TABLE DIM_SEDES (
    sede_key INT AUTO_INCREMENT PRIMARY KEY,
    nombre_sede VARCHAR(50) NOT NULL,
    ciudad_municipio VARCHAR(50) NOT NULL,
    departamento_geo VARCHAR(50) NOT NULL,          -- Departamento de El Salvador
    zona_geografica VARCHAR(30) NOT NULL           -- Central, Occidental, Oriental
) ENGINE=InnoDB;

-- Dimensión: Tiempo
CREATE TABLE DIM_TIEMPO (
    tiempo_key INT PRIMARY KEY,                     -- Formato AAAAMMDD (Ej: 20260522)
    fecha_completa DATE NOT NULL,
    año INT NOT NULL,
    mes INT NOT NULL,
    nombre_mes VARCHAR(15) NOT NULL,
    trimestre VARCHAR(2) NOT NULL                   -- T1, T2, T3, T4
) ENGINE=InnoDB;


-- 3. CREACIÓN DE LA TABLA HECHOS (FACT TABLE)

CREATE TABLE FACT_SALARIOS (
    salario_id INT AUTO_INCREMENT PRIMARY KEY,
    empleado_key INT NOT NULL,
    departamento_key INT NOT NULL,
    sede_key INT NOT NULL,
    tiempo_key INT NOT NULL,
    salario_base DECIMAL(10,2) NOT NULL,
    bonos DECIMAL(10,2) DEFAULT 0.00,
    deducciones DECIMAL(10,2) DEFAULT 0.00,
    salario_neto DECIMAL(10,2) NOT NULL,            -- Calculado como: base + bonos - deducciones
    
    -- Restricciones de Llaves Foráneas (Garantizan la integridad del Modelo Estrella)
    CONSTRAINT FK_fact_empleado FOREIGN KEY (empleado_key) 
        REFERENCES DIM_EMPLEADOS(empleado_key) ON DELETE RESTRICT ON UPDATE CASCADE,
        
    CONSTRAINT FK_fact_departamento FOREIGN KEY (departamento_key) 
        REFERENCES DIM_DEPARTAMENTOS(departamento_key) ON DELETE RESTRICT ON UPDATE CASCADE,
        
    CONSTRAINT FK_fact_sede FOREIGN KEY (sede_key) 
        REFERENCES DIM_SEDES(sede_key) ON DELETE RESTRICT ON UPDATE CASCADE,
        
    CONSTRAINT FK_fact_tiempo FOREIGN KEY (tiempo_key) 
        REFERENCES DIM_TIEMPO(tiempo_key) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;


-- 4. POBLAR DATOS MAESTROS INICIALES

-- Insertar Departamentos estándar de una empresa
INSERT INTO DIM_DEPARTAMENTOS (nombre_departamento) VALUES 
('Tecnología y Sistemas'),
('Recursos Humanos'),
('Finanzas y Contabilidad'),
('Ventas y Mercadeo'),
('Operaciones y Logística');

-- Insertar Sedes distribuidas en El Salvador
INSERT INTO DIM_SEDES (nombre_sede, ciudad_municipio, departamento_geo, zona_geografica) VALUES 
('Sede Central Escalón', 'San Salvador', 'San Salvador', 'Zona Central'),
('Sucursal Santa Tecla', 'Santa Tecla', 'La Libertad', 'Zona Central'),
('Sede Occidente', 'Santa Ana', 'Santa Ana', 'Zona Occidental'),
('Sede Oriente', 'San Miguel', 'San Miguel', 'Zona Oriental');

-- Insertar un catálogo básico de Tiempo para el análisis histórico (Año 2026 completo)
INSERT INTO DIM_TIEMPO (tiempo_key, fecha_completa, año, mes, nombre_mes, trimestre) VALUES 
(20260131, '2026-01-31', 2026, 1, 'Enero', 'T1'),
(20260228, '2026-02-28', 2026, 2, 'Febrero', 'T1'),
(20260331, '2026-03-31', 2026, 3, 'Marzo', 'T1'),
(20260430, '2026-04-30', 2026, 4, 'Abril', 'T2'),
(20260531, '2026-05-31', 2026, 5, 'Mayo', 'T2'),
(20260630, '2026-06-30', 2026, 6, 'Junio', 'T2'),
(20260731, '2026-07-31', 2026, 7, 'Julio', 'T3'),
(20260831, '2026-08-31', 2026, 8, 'Agosto', 'T3'),
(20260930, '2026-09-30', 2026, 9, 'Septiembre', 'T3'),
(20261031, '2026-10-31', 2026, 10, 'Octubre', 'T4'),
(20261130, '2026-11-30', 2026, 11, 'Noviembre', 'T4'),
(20261231, '2026-12-31', 2026, 12, 'Diciembre', 'T4');


-- 5. CREACIÓN DE LOGICA PARA GENERACIÓN DE DATOS SIMULADOS

DELIMITER $$

-- Procedimiento para generar 100 empleados
CREATE PROCEDURE PoblarEmpleadosAleatorios()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE v_dui VARCHAR(10);
    DECLARE v_nombre VARCHAR(100);
    DECLARE v_genero VARCHAR(15);
    DECLARE v_puesto VARCHAR(50);
    
    DECLARE nombres_m TEXT DEFAULT 'Juan,Carlos,Miguel,Luis,Jose,Roberto,David,Fernando,Jorge,Alejandro';
    DECLARE nombres_f TEXT DEFAULT 'Maria,Ana,Elena,Laura,Carmen,Sofia,Gabriela,Patricia,Sandra,Beatriz';
    DECLARE apellidos TEXT DEFAULT 'Martinez,Rodriguez,Lopez,Perez,Gomez,Flores,Hernandez,Vasquez,Ramirez,Sanchez';
    DECLARE puestos TEXT DEFAULT 'Desarrollador Junior,Desarrollador Senior,Analista de Datos,Especialista RRHH,Contador,Ejecutivo de Ventas,Supervisor de Logistica,Soporte Tecnico';

    WHILE i <= 100 DO
        SET v_dui = CONCAT(LPAD(FLOOR(10000000 + (RAND() * 80000000)), 8, '0'), '-', MOD(i, 10));
        
        IF RAND() > 0.5 THEN
            SET v_genero = 'Masculino';
            SET v_nombre = CONCAT(
                SUBSTRING_INDEX(SUBSTRING_INDEX(nombres_m, ',', FLOOR(1 + (RAND() * 10))), ',', -1), ' ',
                SUBSTRING_INDEX(SUBSTRING_INDEX(apellidos, ',', FLOOR(1 + (RAND() * 10))), ',', -1)
            );
        ELSE
            SET v_genero = 'Femenino';
            SET v_nombre = CONCAT(
                SUBSTRING_INDEX(SUBSTRING_INDEX(nombres_f, ',', FLOOR(1 + (RAND() * 10))), ',', -1), ' ',
                SUBSTRING_INDEX(SUBSTRING_INDEX(apellidos, ',', FLOOR(1 + (RAND() * 10))), ',', -1)
            );
        END IF;
        
        SET v_puesto = SUBSTRING_INDEX(SUBSTRING_INDEX(puestos, ',', FLOOR(1 + (RAND() * 8))), ',', -1);
        
        INSERT INTO DIM_EMPLEADOS (dui, nombre_completo, genero, puesto_cargo)
        VALUES (v_dui, v_nombre, v_genero, v_puesto);
        
        SET i = i + 1;
    END WHILE;
END$$

-- Procedimiento para generar los 1,200 registros de salarios cruzados
CREATE PROCEDURE PoblarFactSalariosHistorico()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE emp_id INT;
    DECLARE temp_id INT;
    
    DECLARE v_base DECIMAL(10,2);
    DECLARE v_bono DECIMAL(10,2);
    DECLARE v_deduc DECIMAL(10,2);
    DECLARE v_neto DECIMAL(10,2);
    
    DECLARE v_depto INT;
    DECLARE v_sede INT;

    DECLARE cur_empleados CURSOR FOR SELECT empleado_key FROM DIM_EMPLEADOS;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur_empleados;

    read_loop: LOOP
        FETCH cur_empleados INTO emp_id;
        IF done THEN
            LEAVE read_loop;
        END IF;

        SET v_base = ROUND(500 + (RAND() * 2500), 2); -- Salarios entre $500 y $3000
        SET v_depto = FLOOR(1 + (RAND() * 5));        -- Uno de los 5 departamentos
        SET v_sede = FLOOR(1 + (RAND() * 4));         -- Una de las 4 sedes

        BLOCK2: BEGIN
            DECLARE done_time INT DEFAULT FALSE;
            DECLARE cur_tiempo CURSOR FOR SELECT tiempo_key FROM DIM_TIEMPO;
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_time = TRUE;
            
            OPEN cur_tiempo;
            time_loop: LOOP
                FETCH cur_tiempo INTO temp_id;
                IF done_time THEN
                    LEAVE time_loop;
                END IF;

                SET v_bono = IF(RAND() > 0.7, ROUND(50 + (RAND() * 200), 2), 0.00); 
                SET v_deduc = ROUND(v_base * 0.095, 2); -- Descuentos ISSS + AFP aprox
                SET v_neto = v_base + v_bono - v_deduc;

                INSERT INTO FACT_SALARIOS (empleado_key, departamento_key, sede_key, tiempo_key, salario_base, bonos, deducciones, salario_neto)
                VALUES (emp_id, v_depto, v_sede, temp_id, v_base, v_bono, v_deduc, v_neto);

            END LOOP time_loop;
            CLOSE cur_tiempo;
        END BLOCK2;

    END LOOP read_loop;

    CLOSE cur_empleados;
END$$

DELIMITER ;


-- 6. EJECUCIÓN INMEDIATA PARA COMPLETAR LA BASE DE DATOS

CALL PoblarEmpleadosAleatorios();
CALL PoblarFactSalariosHistorico();

-- 7. VERIFICACIÓN DE CONTEOS DE REGISTROS
-- Comprueba que las dimensiones tienen datos y la tabla Fact superó el mínimo de 1,000 filas.

SELECT 'DIM_DEPARTAMENTOS' AS tabla, COUNT(*) AS total_registros FROM DIM_DEPARTAMENTOS
UNION ALL
SELECT 'DIM_SEDES', COUNT(*) FROM DIM_SEDES
UNION ALL
SELECT 'DIM_TIEMPO', COUNT(*) FROM DIM_TIEMPO
UNION ALL
SELECT 'DIM_EMPLEADOS', COUNT(*) FROM DIM_EMPLEADOS
UNION ALL
SELECT 'FACT_SALARIOS', COUNT(*) FROM FACT_SALARIOS;

-- 8. CONSULTAR DIMENSIONES MAESTRAS (PEQUEÑAS)

-- Ver todos los departamentos de la empresa (5 registros)
SELECT * FROM DIM_DEPARTAMENTOS;

-- Ver todas las sedes configuradas en El Salvador (4 registros)
SELECT * FROM DIM_SEDES;

-- Ver el calendario de meses para el análisis histórico (12 registros)
SELECT * FROM DIM_TIEMPO;


-- 9. CONSULTAR DIMENSIÓN DE EMPLEADOS

-- Ver los 100 empleados generados aleatoriamente con sus DUIs y puestos
SELECT * FROM DIM_EMPLEADOS;


-- 10. CONSULTAR TABLA DE HECHOS (LA MÁS GRANDE)

-- Ver los 1,200 registros de pagos mensuales de salarios
SELECT * FROM FACT_SALARIOS;

-- 11. Consulta para verificacion de datos
SELECT 
    f.salario_id,
    e.nombre_completo AS empleado,
    e.puesto_cargo AS puesto,
    d.nombre_departamento AS departamento,
    s.nombre_sede AS sede,
    s.departamento_geo AS departamento_salvador,
    t.nombre_mes AS mes_pago,
    f.salario_base,
    f.bonos,
    f.deducciones,
    f.salario_neto
FROM FACT_SALARIOS f
JOIN DIM_EMPLEADOS e ON f.empleado_key = e.empleado_key
JOIN DIM_DEPARTAMENTOS d ON f.departamento_key = d.departamento_key
JOIN DIM_SEDES s ON f.sede_key = s.sede_key
JOIN DIM_TIEMPO t ON f.tiempo_key = t.tiempo_key
LIMIT 5;


