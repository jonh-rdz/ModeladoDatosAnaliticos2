# -*- coding: utf-8 -*-
"""
Created on Thu May 21 22:18:06 2026

@author: jrodr
"""

# ==============================================================================
# Archivo: snowflake_bi_dashboard.py
# Arquitectura: Lee la Vista Optimizada, usa Pandas para formateo final y 
#               Seaborn para renderizar Dashboards Analíticos.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. IMPORTACIÓN DE LIBRERÍAS
# ------------------------------------------------------------------------------
import pandas as pd                 # Estándar de la industria para manipulación de DataFrames.
from sqlalchemy import create_engine, exc # ORM para conexión segura a bases de datos relacionales.
import logging                      # Sistema de bitácoras para auditar la ejecución en producción.
import matplotlib.pyplot as plt       # Motor gráfico base.
import seaborn as sns               # Capa superior de matplotlib para gráficos estéticos y estadísticos.

# ------------------------------------------------------------------------------
# 2. CONFIGURACIÓN DEL SISTEMA DE LOGS (Trazabilidad)
# ------------------------------------------------------------------------------
# Usamos logger para guardar historial de ejecución.
logging.basicConfig(
    level=logging.INFO, 
    format='%(asctime)s - [BI_ENGINE] - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ------------------------------------------------------------------------------
# 3. CLASE DEL MOTOR DE BUSINESS INTELLIGENCE
# ------------------------------------------------------------------------------
class SnowflakeDashboard:
    
    # Método constructor: Configura la conexión a la BD al instanciar la clase
    def __init__(self, db_uri="mysql+pymysql://root:@localhost:3306/hr_snowflake_analytics"):
        self.engine = create_engine(db_uri) # Crea el motor de conexión de SQLAlchemy
        self.df_data = pd.DataFrame()       # Inicializa el DataFrame vacío de forma segura

    # --------------------------------------------------------------------------
    # MÉTODOS DE EXTRACCIÓN
    # --------------------------------------------------------------------------
    def fetch_analytical_view(self):
        """
        Se conecta a MySQL y extrae el resultado de la vista 'vw_snowflake_analisis'.
        Como la vista ya tiene CTEs y Window Functions.
        """
        logger.info("Iniciando conexión y extracción de datos desde MySQL...")
        try:
            # pd.read_sql ejecuta la consulta y convierte el resultado directamente a DataFrame
            self.df_data = pd.read_sql("SELECT * FROM vw_snowflake_analisis;", self.engine)
            logger.info(f"Éxito. Se extrajeron {len(self.df_data)} registros procesados.")
            
        except exc.SQLAlchemyError as e:
            # Si MySQL está apagado o la clave es incorrecta, capturamos el error aquí
            logger.critical(f"Error de conexión a la base de datos: {e}")
            raise

    # --------------------------------------------------------------------------
    # MÉTODOS DE TRANSFORMACIÓN EN MEMORIA Y CONSOLA
    # --------------------------------------------------------------------------
    def print_executive_summary(self):
        """
        Imprime un resumen de los requerimientos analíticos en la terminal.
        """
        # Validación de seguridad: no procesar si no hay datos
        if self.df_data.empty:
            logger.warning("El DataFrame está vacío. Asegúrate de ejecutar el SP en MySQL.")
            return

        print("\n" + "="*80)
        print("REPORTE GERENCIAL: RECURSOS HUMANOS (1500+ EMPLEADOS)".center(80))
        print("="*80)
        
        # Requerimiento: Promedio Salarial Global
        promedio_global = self.df_data['salario_neto'].mean()
        print(f"Salario Neto Promedio Global: ${promedio_global:,.2f}\n")

        # Requerimiento: Salarios por Región (Agrupación)
        print("GASTO SALARIAL POR REGIÓN:")
        # Agrupamos por región, sumamos el neto y ordenamos de mayor a menor
        kpi_region = self.df_data.groupby('nombre_region')['salario_neto'].sum().sort_values(ascending=False)
        # Formateamos los números a String con formato de moneda
        print(kpi_region.apply(lambda x: f"${x:,.2f}").to_string())
        print("-" * 80)

        # Requerimiento: Top 10 Empleados con Mayor Salario
        print("TOP 10 EMPLEADOS MEJOR PAGADOS (A nivel global):")
        # .nlargest es una función optimizada de pandas equivalente a ORDER BY DESC LIMIT 10
        top_10 = self.df_data.nlargest(10, 'salario_neto')[
            ['nombre_completo', 'nombre_puesto', 'nombre_departamento', 'salario_neto']
        ]
        # Imprimimos sin el índice numérico y aplicando formato al salario
        print(top_10.to_string(index=False, formatters={'salario_neto': lambda x: f"${x:,.2f}"}))
        print("="*80 + "\n")

    # --------------------------------------------------------------------------
    # MÉTODOS DE VISUALIZACIÓN (Capa Final)
    # --------------------------------------------------------------------------
    def render_dashboards(self):
        """
        Genera gráficos interactivos utilizando Seaborn y Matplotlib.
        """
        if self.df_data.empty: return
        
        logger.info("Generando gráficos y preparando el renderizado en pantalla...")
        
        # Configuramos el fondo oscuro profesional
        sns.set_theme(style="darkgrid", context="paper")
        
        # Creamos una figura dividida en 1 fila y 2 columnas
        fig, axes = plt.subplots(1, 2, figsize=(16, 6))
        fig.suptitle('Dashboard Analítico: Estructura Copo de Nieve (1500+ Registros)', 
                     fontsize=16, fontweight='bold', y=1.02)
        
        # -- GRÁFICO 1: Gasto Total por Departamento --
        # Agrupamos los datos
        gasto_depto = self.df_data.groupby('nombre_departamento')['salario_neto'].sum().reset_index()
        gasto_depto = gasto_depto.sort_values('salario_neto', ascending=False)
        
        # Renderizamos el gráfico de barras en la posición [0]
        sns.barplot(
            data=gasto_depto, x='nombre_departamento', y='salario_neto', 
            ax=axes[0], palette='viridis', hue='nombre_departamento', legend=False
        )
        axes[0].set_title('Inversión Total de Nómina por Departamento', fontweight='bold')
        axes[0].set_ylabel('Inversión (USD)')
        axes[0].set_xlabel('')
        axes[0].tick_params(axis='x', rotation=15) # Rotamos el texto del eje X 15 grados
        
        # -- GRÁFICO 2: Distribución de Salarios por Puesto --
        # Agrupamos calculando el promedio por cada puesto
        promedio_puesto = self.df_data.groupby('nombre_puesto')['salario_neto'].mean().reset_index()
        promedio_puesto = promedio_puesto.sort_values('salario_neto', ascending=False)
        
        # Renderizamos barras horizontales en la posición [1]
        sns.barplot(
            data=promedio_puesto, x='salario_neto', y='nombre_puesto', 
            ax=axes[1], palette='rocket', hue='nombre_puesto', legend=False
        )
        axes[1].set_title('Promedio Salarial por Rol', fontweight='bold')
        axes[1].set_xlabel('Salario Promedio (USD)')
        axes[1].set_ylabel('')
        
        # sns.despine() elimina los bordes superior y derecho del gráfico haciéndolo más limpio
        sns.despine()
        
        # Ajusta automáticamente los espaciados para evitar que los textos se superpongan
        plt.tight_layout()
        
        # Muestra la ventana de la interfaz gráfica
        plt.show()
        logger.info("Proceso analítico concluido exitosamente.")

# ==============================================================================
# PUNTO DE ENTRADA PRINCIPAL
# ==============================================================================
# Verifica que el script se está ejecutando directamente y no siendo importado
if __name__ == "__main__":
    
    # 1. Instanciamos nuestra clase principal
    dashboard = SnowflakeDashboard()
    
    try:
        # 2. Orquestamos la ejecución secuencial de los métodos
        dashboard.fetch_analytical_view()   # Conecta y extrae
        dashboard.print_executive_summary() # Analiza e imprime en consola
        dashboard.render_dashboards()       # Dibuja la interfaz visual
        
    except Exception as e:
        # 3. Captura global de errores: Si algo falla, el logger lo registra sin "romper" la consola brutalmente.
        logger.critical(f"La ejecución falló por el siguiente motivo: {e}")