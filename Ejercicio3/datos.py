import pandas as pd
import numpy as np

n = 5000
fact_ventas = pd.DataFrame({'id_venta': range(1, n+1), 'id_producto': np.random.randint(1, 51, n), 'cantidad': np.random.randint(1, 10, n), 'precio': np.random.uniform(10, 500, n)})
dim_prod = pd.DataFrame({'id_producto': range(1, 51), 'nombre_producto': [f'P_{i}' for i in range(1, 51)], 'id_categoria': np.random.randint(1, 6, 50)})
dim_cat = pd.DataFrame({'id_categoria': range(1, 6), 'nombre_categoria': ['Electronica', 'Hogar', 'Ropa', 'Deportes', 'Juguetes']})

fact_ventas.to_csv('fact_ventas.csv', index=False)
dim_prod.to_csv('dim_prod.csv', index=False)
dim_cat.to_csv('dim_cat.csv', index=False)
print("Archivos CSV creados.")