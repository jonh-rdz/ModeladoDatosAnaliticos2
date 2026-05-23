import pandas as pd
import pymysql
import matplotlib.pyplot as plt
import seaborn as sns

# 1. CONEXIÓN A LA BASE DE DATOS
# Modifica 'tu_password' con la contraseña real de tu MySQL Workbench
conexion = pymysql.connect(
    host="localhost",
    user="root",
    password="root",  
    database="star_schema"
)

# 2. EXTRACCIÓN DE DATOS UNIFICADOS
# Traemos la información numérica de la tabla Fact cruzada con las dimensiones descriptivas
query_kpi = """
SELECT 
    d.nombre_departamento AS departamento, 
    s.nombre_sede AS sede, 
    s.zona_geografica AS zona, 
    f.salario_neto
FROM FACT_SALARIOS f
JOIN DIM_DEPARTAMENTOS d ON f.departamento_key = d.departamento_key
JOIN DIM_SEDES s ON f.sede_key = s.sede_key;
"""

df = pd.read_sql(query_kpi, conexion)
conexion.close()  # Cerramos la conexión para liberar recursos

# 3. CONFIGURACIÓN DEL LIENZO DE GRÁFICOS
sns.set_theme(style="whitegrid")
fig, axes = plt.subplots(2, 2, figsize=(16, 11))
fig.suptitle('Dashboard de KPIs Empresariales - Análisis de Salarios', fontsize=16, fontweight='bold', color='#1a5f7a')

# ========================================================
# KPI 1: Costo Total de Planilla por Departamento (Barras Horizontales)
# ========================================================
df_depto = df.groupby('departamento')['salario_neto'].sum().reset_index().sort_values(by='salario_neto', ascending=False)
sns.barplot(
    data=df_depto, 
    x='salario_neto', 
    y='departamento', 
    ax=axes[0, 0], 
    palette='Blues_r'
)
axes[0, 0].set_title('Costo Total de Planilla por Departamento ($)', fontsize=12, fontweight='bold')
axes[0, 0].set_xlabel('Suma de Salarios Netos')
axes[0, 0].set_ylabel('')

# ========================================================
# KPI 2: Distribución del Gasto Salarial por Sede (Gráfico de Pastel)
# ========================================================
df_sede = df.groupby('sede')['salario_neto'].sum().reset_index()
axes[0, 1].pie(
    df_sede['salario_neto'], 
    labels=df_sede['sede'], 
    autopct='%1.1f%%', 
    colors=sns.color_palette('pastel'),
    startangle=90
)
axes[0, 1].set_title('Distribución Porcentual del Gasto por Sede Física', fontsize=12, fontweight='bold')

# ========================================================
# KPI 3: Salario Neto Promedio por Zona Geográfica (Barras Verticales)
# ========================================================
df_zona = df.groupby('zona')['salario_neto'].mean().reset_index().sort_values(by='salario_neto', ascending=False)
sns.barplot(
    data=df_zona, 
    x='zona', 
    y='salario_neto', 
    ax=axes[1, 0], 
    palette='magma'
)
axes[1, 0].set_title('Salario Neto Promedio por Zona Geográfica ($)', fontsize=12, fontweight='bold')
axes[1, 0].set_xlabel('Zonas de El Salvador')
axes[1, 0].set_ylabel('Promedio ($)')

# ========================================================
# KPI 4: Tarjeta de Métricas Globales (Estilo Cuadro de Control)
# ========================================================
axes[1, 1].axis('off')  # Ocultamos la cuadrícula para diseñar texto limpio
promedio_global = df['salario_neto'].mean()
planilla_anual = df['salario_neto'].sum()

# Dibujar métrica de Promedio Mensual
axes[1, 1].text(0.5, 0.75, f"${promedio_global:,.2f}", fontsize=28, weight='bold', ha='center', color='#1a5f7a')
axes[1, 1].text(0.5, 0.62, "Salario Neto Promedio Mensual", fontsize=11, ha='center', color='gray', weight='bold')

# Dibujar métrica de Inversión Total Histórica
axes[1, 1].text(0.5, 0.30, f"${planilla_anual:,.2f}", fontsize=28, weight='bold', ha='center', color='#b70404')
axes[1, 1].text(0.5, 0.17, "Inversión Total Acumulada en Planilla", fontsize=11, ha='center', color='gray', weight='bold')

# Ajustar márgenes para que no se encimen los textos
plt.tight_layout()
plt.show()