CREATE DATABASE IF NOT EXISTS Ejercicio3_DB;
USE Ejercicio3_DB;

-- FACT TABLE
CREATE TABLE FACT_VENTAS (
    id_venta INT PRIMARY KEY,
    id_producto INT,
    cantidad INT,
    precio DECIMAL(10,2)
);

-- ESTRUCTURA STAR
CREATE TABLE DIM_PRODUCTOS_STAR (
    id_producto INT PRIMARY KEY,
    nombre_producto VARCHAR(100),
    nombre_categoria VARCHAR(50)
);

-- ESTRUCTURA SNOWFLAKE
CREATE TABLE DIM_CATEGORIAS (
    id_categoria INT PRIMARY KEY,
    nombre_categoria VARCHAR(50)
);

CREATE TABLE DIM_PRODUCTOS_SNOW (
    id_producto INT PRIMARY KEY,
    nombre_producto VARCHAR(100),
    id_categoria INT
);