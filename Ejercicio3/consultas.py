import mysql.connector
import time

# Conexión actualizada con tu contraseña
try:
    db = mysql.connector.connect(
        host="localhost", 
        user="root", 
        password="2006", 
        database="Ejercicio3_DB"
    )
    cursor = db.cursor()
    print("Conexión exitosa a MySQL.")
except mysql.connector.Error as err:
    print(f"Error: {err}")
    exit()

# Función para medir tiempos
def ejecutar_y_medir(query):
    start = time.perf_counter()
    cursor.execute(query)
    cursor.fetchall()
    return time.perf_counter() - start

# Consultas para comparar
q_star = "SELECT p.nombre_categoria, SUM(f.precio) FROM FACT_VENTAS f JOIN DIM_PRODUCTOS_STAR p ON f.id_producto = p.id_producto GROUP BY p.nombre_categoria"
q_snow = "SELECT c.nombre_categoria, SUM(f.precio) FROM FACT_VENTAS f JOIN DIM_PRODUCTOS_SNOW p ON f.id_producto = p.id_producto JOIN DIM_CATEGORIAS c ON p.id_categoria = c.id_categoria GROUP BY c.nombre_categoria"

# Medición
t_star = ejecutar_y_medir(q_star)
t_snow = ejecutar_y_medir(q_snow)

print(f"Tiempo Star: {t_star:.6f}s")
print(f"Tiempo Snowflake: {t_snow:.6f}s")

db.close()