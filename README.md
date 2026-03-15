# 🚀 LABORATORIO DE OPTIMIZACIÓN DE SQL SERVER

**Laboratorio de Optimización de SQL Server** es un proyecto educativo completo diseñado para enseñar técnicas avanzadas de optimización de consultas, creación de índices y análisis de rendimiento en SQL Server.

> *"El rendimiento no es un accidente, es el resultado de un diseño cuidadoso."*

---

## 🎯 ¿Qué es este Proyecto?

Este laboratorio proporciona un entorno práctico para aprender y experimentar con:

- **Generación de datos masivos** para pruebas de rendimiento
- **Identificación de consultas lentas** y sus causas
- **Creación estratégica de índices** para optimización
- **Comparación de rendimiento** antes y después de optimizar
- **Análisis de execution plans** para diagnóstico

---

## 📚 ¿Qué Aprenderás?

### 🔍 Análisis de Rendimiento
- Identificación de cuellos de botella en consultas
- Uso de estadísticas de tiempo e I/O
- Interpretación de execution plans
- Detección de table scans y index scans costosos

### 📊 Optimización con Índices
- Tipos de índices (clustered, nonclustered, covering, filtered)
- Estrategias de indexación para diferentes escenarios
- Índices compuestos y columnas incluidas
- Vistas indexadas para consultas complejas

### ⚡ Mejora de Consultas
- Reescritura de consultas ineficientes
- Eliminación de subconsultas correlacionadas
- Reemplazo de cursores con operaciones set-based
- Optimización de joins y agregaciones

### 📈 Monitoreo y Diagnóstico
- DMVs para análisis de rendimiento
- Detección de índices faltantes
- Estadísticas de uso de índices
- Query Store para seguimiento histórico

---

## 🗂️ Estructura del Proyecto

```
EjemploListeners/
├── scripts/
│   ├── datasets/
│   │   └── 01_generar_datos_masivos.sql    # Genera 2M+ registros de prueba
│   ├── slow_queries/
│   │   └── 01_consultas_lentas_ejemplos.sql  # 10 consultas ineficientes
│   ├── indexes/
│   │   └── 01_creacion_indices.sql           # Índices de optimización
│   └── performance_tests/
│       ├── 01_comparacion_rendimiento.sql    # Pruebas antes/después
│       └── 02_execution_plan_examples.sql    # Análisis de planes
└── README.md
```

---

## 🛠️ Cómo Ejecutar los Scripts

### Requisitos Previos

- **SQL Server 2016** o superior (Express, Developer, Enterprise)
- **SQL Server Management Studio (SSMS)** o **Azure Data Studio**
- Permisos de creación de bases de datos

### Paso a Paso

#### 1. Generar Datos de Prueba

```sql
-- Ejecutar primero: scripts/datasets/01_generar_datos_masivos.sql
-- Este script crea:
--   • 100,000 Clientes
--   • 10,000 Productos
--   • 500,000 Pedidos
--   • 1,500,000 Detalles de Pedido
```

**Tiempo estimado:** 5-10 minutos

#### 2. Analizar Consultas Lentas

```sql
-- Ejecutar: scripts/slow_queries/01_consultas_lentas_ejemplos.sql
-- Use Ctrl+L en SSMS para ver el execution plan estimado
-- Active: SET STATISTICS TIME ON; SET STATISTICS IO ON;
```

#### 3. Crear Índices de Optimización

```sql
-- Ejecutar: scripts/indexes/01_creacion_indices.sql
-- Crea índices estratégicos para cada consulta lenta
```

#### 4. Comparar Rendimiento

```sql
-- Ejecutar: scripts/performance_tests/01_comparacion_rendimiento.sql
-- Compare estadísticas de TIME e IO antes y después
```

#### 5. Estudiar Execution Plans

```sql
-- Ejecutar: scripts/performance_tests/02_execution_plan_examples.sql
-- Analice operadores costosos y sugerencias de índices
```

---

## 📝 Ejemplos de Uso

### Ejemplo 1: Identificar Table Scan

```sql
-- Sin índice: TABLE SCAN (lento)
SELECT * FROM dbo.Clientes WHERE Apellido = 'García';

-- Con índice: INDEX SEEK (rápido)
CREATE INDEX IX_Clientes_Apellido ON dbo.Clientes(Apellido);
SELECT ClienteID, Nombre, Apellido FROM dbo.Clientes WHERE Apellido = 'García';
```

### Ejemplo 2: Reemplazar Subconsulta Correlacionada

```sql
-- LENTO: Subconsulta por cada fila
SELECT 
    c.ClienteID,
    (SELECT COUNT(*) FROM Pedidos p WHERE p.ClienteID = c.ClienteID) AS TotalPedidos
FROM Clientes c;

-- RÁPIDO: JOIN con GROUP BY
SELECT 
    c.ClienteID,
    COUNT(p.PedidoID) AS TotalPedidos
FROM Clientes c
LEFT JOIN Pedidos p ON c.ClienteID = p.ClienteID
GROUP BY c.ClienteID;
```

### Ejemplo 3: Índice Covering

```sql
-- Índice que incluye todas las columnas necesarias
CREATE INDEX IX_Pedidos_Fecha_Covering 
ON dbo.Pedidos(FechaPedido)
INCLUDE (ClienteID, Total, Estado);

-- Esta consulta usa solo el índice (sin acceso a la tabla)
SELECT FechaPedido, ClienteID, Total, Estado 
FROM dbo.Pedidos 
WHERE FechaPedido >= '2025-01-01';
```

---

## 📊 Métricas de Rendimiento

### Antes de Optimizar

| Consulta | Tiempo Promedio | Lecturas Lógicas |
|----------|----------------|------------------|
| Búsqueda Email | 2500 ms | 150,000 |
| Join Pedidos | 8000 ms | 500,000 |
| Agrupación Categoría | 1500 ms | 80,000 |

### Después de Optimizar

| Consulta | Tiempo Promedio | Lecturas Lógicas | Mejora |
|----------|----------------|------------------|--------|
| Búsqueda Email | 50 ms | 500 | 50x |
| Join Pedidos | 200 ms | 15,000 | 40x |
| Agrupación Categoría | 30 ms | 2,000 | 50x |

---

## 🔧 Comandos Útiles

### Ver Índices Existentes

```sql
SELECT 
    t.name AS Tabla,
    i.name AS Indice,
    i.type_desc AS Tipo,
    STRING_AGG(c.name, ', ') AS Columnas
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
GROUP BY t.name, i.name, i.type_desc;
```

### Ver Índices Faltantes Sugeridos

```sql
SELECT 
    'CREATE INDEX [IX_' + OBJECT_NAME(mid.object_id) + '_' + 
    REPLACE(REPLACE(REPLACE(ISNULL(equality_columns,'') + ISNULL(inequality_columns,''), '[', ''), ']', ''), ', ', '_') + 
    '] ON ' + statement + 
    ' (' + ISNULL(equality_columns,'') + 
    CASE WHEN equality_columns IS NOT NULL AND inequality_columns IS NOT NULL THEN ', ' ELSE '' END +
    ISNULL(inequality_columns,'') + ')' +
    ISNULL(' INCLUDE (' + included_columns + ')', '') AS CreateIndexStatement,
    avg_user_impact,
    user_seeks,
    user_scans
FROM sys.dm_db_missing_index_details mid
JOIN sys.dm_db_missing_index_group_stats migs ON mid.index_handle = migs.index_handle
ORDER BY avg_user_impact * (user_seeks + user_scans) DESC;
```

### Limpiar Cache de Planes

```sql
-- Útil para pruebas de rendimiento limpias
DBCC FREEPROCCACHE;
DBCC DROPCLEANBUFFERS;
```

---

## 🎓 Conceptos Clave

### Execution Plan Operators

| Operador | Descripción | Costo |
|----------|-------------|-------|
| **Table Scan** | Escanea toda la tabla | Alto |
| **Index Scan** | Escanea todo el índice | Medio |
| **Index Seek** | Búsqueda directa en índice | Bajo |
| **Key Lookup** | Búsqueda adicional en tabla | Medio-Alto |
| **Hash Join** | Join usando tabla hash | Variable |
| **Nested Loops** | Join iterativo | Bajo (pequeños datos) |
| **Merge Join** | Join de datos ordenados | Bajo (datos ordenados) |

### Tipos de Índices

- **Clustered Index**: Ordena físicamente los datos (uno por tabla)
- **Nonclustered Index**: Estructura separada con punteros
- **Covering Index**: Incluye todas las columnas de la consulta
- **Filtered Index**: Índice parcial con condición WHERE
- **Composite Index**: Múltiples columnas en orden específico

---

## ⚠️ Mejores Prácticas

### ✅ Hacer

- Analizar execution plans antes de optimizar
- Crear índices basados en consultas frecuentes
- Usar índices covering para consultas críticas
- Monitorear uso de índices regularmente
- Actualizar estadísticas periódicamente

### ❌ No Hacer

- Crear índices sin analizar el workload real
- Indexar todas las columnas "por si acaso"
- Ignorar el mantenimiento de índices existentes
- Usar hints de índice sin comprensión profunda
- Olvidar el impacto en operaciones INSERT/UPDATE/DELETE

---

## 📖 Recursos Adicionales

### Documentación Oficial

- [SQL Server Documentation](https://docs.microsoft.com/sql/sql-server/)
- [Execution Plan Reference](https://docs.microsoft.com/sql/relational-databases/showplan-logical-and-physical-operators-reference)
- [Index Design Guide](https://docs.microsoft.com/sql/relational-databases/sql-server-index-design-guide)

### Herramientas Recomendadas

- **SQL Server Management Studio (SSMS)** - IDE oficial
- **Azure Data Studio** - Editor moderno multiplataforma
- **SQL Profiler** - Captura y análisis de eventos
- **Extended Events** - Sistema de monitoreo ligero

---

## 🧪 Ejercicios Prácticos

### Nivel Básico

1. Ejecutar la generación de datos
2. Identificar consultas con Table Scan
3. Crear índices simples para columnas de filtro

### Nivel Intermedio

1. Analizar execution plans complejos
2. Crear índices covering para consultas específicas
3. Reescribir subconsultas correlacionadas

### Nivel Avanzado

1. Implementar vistas indexadas
2. Optimizar consultas con múltiples joins
3. Configurar Query Store para seguimiento

---

## 👨‍💻 Desarrollado por Isaac Esteban Haro Torres

**Ingeniero en Sistemas · Full Stack · Automatización · Data**

- 📧 Email: zackharo1@gmail.com
- 📱 WhatsApp: 098805517
- 💻 GitHub: https://github.com/ieharo1
- 🌐 Portafolio: https://ieharo1.github.io/portafolio-isaac.haro/

---

© 2026 Isaac Esteban Haro Torres - Todos los derechos reservados.
