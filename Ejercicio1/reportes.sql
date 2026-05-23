USE star_schema;

-- A. Salarios por Departamento
-- Muestra el costo total de la planilla y el promedio mensual por área organizacional
SELECT 
    d.nombre_departamento AS Departamento,
    ROUND(SUM(f.salario_neto), 2) AS Costo_Planilla_Total,
    ROUND(AVG(f.salario_neto), 2) AS Promedio_Salarial_Mensual
FROM FACT_SALARIOS f
JOIN DIM_DEPARTAMENTOS d ON f.departamento_key = d.departamento_key
GROUP BY d.nombre_departamento
ORDER BY Costo_Planilla_Total DESC;


-- B. Salarios por Sede (Desglose Geográfico)
-- Analiza cómo se distribuye el gasto salarial en los departamentos de El Salvador
SELECT 
    s.nombre_sede AS Sede,
    s.departamento_geo AS Departamento_Geografico,
    s.zona_geografica AS Zona,
    ROUND(SUM(f.salario_neto), 2) AS Gasto_Salarial_Sede,
    ROUND(AVG(f.salario_neto), 2) AS Promedio_Sede
FROM FACT_SALARIOS f
JOIN DIM_SEDES s ON f.sede_key = s.sede_key
GROUP BY s.nombre_sede, s.departamento_geo, s.zona_geografica
ORDER BY Gasto_Salarial_Sede DESC;


-- C. Promedio Salarial General del Negocio
-- KPI Global de la empresa que sirve como línea base
SELECT 
    ROUND(AVG(f.salario_base), 2) AS Promedio_Salario_Base,
    ROUND(AVG(f.bonos), 2) AS Promedio_Bonos_Mensuales,
    ROUND(AVG(f.salario_neto), 2) AS Promedio_Salario_Neto_General
FROM FACT_SALARIOS f;


-- D. Top Empleados (Los 10 mejores pagados en promedio histórico)
-- Identifica el talento con mayor asignación económica en el año
SELECT 
    e.nombre_completo AS Empleado,
    e.puesto_cargo AS Puesto,
    ROUND(AVG(f.salario_neto), 2) AS Salario_Neto_Promedio_Mensual
FROM FACT_SALARIOS f
JOIN DIM_EMPLEADOS e ON f.empleado_key = e.empleado_key
GROUP BY e.empleado_key, e.nombre_completo, e.puesto_cargo
ORDER BY Salario_Neto_Promedio_Mensual DESC
LIMIT 10;