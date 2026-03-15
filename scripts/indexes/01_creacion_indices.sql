-- ============================================================================
-- CREACIÓN DE ÍNDICES PARA OPTIMIZACIÓN DE CONSULTAS
-- ============================================================================
-- Este script crea índices estratégicos para mejorar el rendimiento de las
-- consultas lentas demostradas en el script anterior.
-- ============================================================================

USE OptimizacionLab;
GO

-- ============================================================================
-- ÍNDICE 1: ÍNDICE EN EMAIL PARA BÚSQUEDAS
-- ============================================================================
-- Mejora: Consulta Lenta 1 - Búsqueda por Email
-- Nota: Para búsquedas con LIKE '%pattern', un índice no ayuda completamente,
-- pero podemos crear un índice filtrado para dominios específicos

-- Índice tradicional en Email (ayuda para búsquedas que comienzan con patrón)
CREATE NONCLUSTERED INDEX IX_Clientes_Email 
ON dbo.Clientes(Email)
INCLUDE (Nombre, Apellido, Telefono);
GO

-- Índice filtrado para emails específicos (más eficiente)
CREATE NONCLUSTERED INDEX IX_Clientes_Email_Gmail
ON dbo.Clientes(Email)
INCLUDE (Nombre, Apellido, Telefono)
WHERE Email LIKE '%gmail.com';
GO

-- ============================================================================
-- ÍNDICE 2: ÍNDICES PARA JOINS DE PEDIDOS
-- ============================================================================
-- Mejora: Consulta Lenta 2 - Join múltiple

-- Índice en ClienteID para el join
CREATE NONCLUSTERED INDEX IX_Pedidos_ClienteID_Fecha
ON dbo.Pedidos(ClienteID)
INCLUDE (FechaPedido, Total, Estado);
GO

-- Índice compuesto para filtrado por fecha
CREATE NONCLUSTERED INDEX IX_Pedidos_FechaPedido
ON dbo.Pedidos(FechaPedido)
INCLUDE (ClienteID, Total, Estado);
GO

-- ============================================================================
-- ÍNDICE 3: ÍNDICES PARA AGREGACIÓN POR CATEGORÍA
-- ============================================================================
-- Mejora: Consulta Lenta 3 - GROUP BY Categoría

CREATE NONCLUSTERED INDEX IX_Productos_Categoria
ON dbo.Productos(Categoria)
INCLUDE (Precio, Stock);
GO

-- Índice covering que incluye todas las columnas necesarias
CREATE NONCLUSTERED INDEX IX_Productos_Categoria_Completo
ON dbo.Productos(Categoria)
INCLUDE (Precio, Stock, Nombre, Descripcion, FechaCreacion);
GO

-- ============================================================================
-- ÍNDICE 4: ÍNDICES PARA SUBCONSULTAS
-- ============================================================================
-- Mejora: Consulta Lenta 4 - Subconsultas correlacionadas

-- Índice para optimizar las subconsultas
CREATE NONCLUSTERED INDEX IX_Pedidos_ClienteID_Covering
ON dbo.Pedidos(ClienteID)
INCLUDE (Total, FechaPedido);
GO

-- ============================================================================
-- ÍNDICE 5: ÍNDICE PARA BÚSQUEDA POR FECHA SIN FUNCIONES
-- ============================================================================
-- Mejora: Consulta Lenta 5 - Uso de funciones en WHERE
-- Nota: La solución real es cambiar la consulta para no usar funciones

-- Índice para rango de fechas
CREATE NONCLUSTERED INDEX IX_Pedidos_FechaRango
ON dbo.Pedidos(FechaPedido)
INCLUDE (ClienteID, Total, Estado);
GO

-- ============================================================================
-- ÍNDICE 6: ÍNDICES PARA JOINS COMPLEJOS
-- ============================================================================
-- Mejora: Consulta Lenta 6 - DISTINCT con joins

-- Índice para el join con DetallePedidos
CREATE NONCLUSTERED INDEX IX_DetallePedidos_PedidoID
ON dbo.DetallePedidos(PedidoID)
INCLUDE (ProductoID, Cantidad, PrecioUnitario, Subtotal);
GO

CREATE NONCLUSTERED INDEX IX_DetallePedidos_ProductoID
ON dbo.DetallePedidos(ProductoID)
INCLUDE (PedidoID, Cantidad);
GO

-- ============================================================================
-- ÍNDICE 7: REESTRUCTURACIÓN DE CONSULTA CON CTE
-- ============================================================================
-- Mejora: Consulta Lenta 8 - Reemplazo de cursor

-- Esta vista indexada permite reemplazar el cursor
CREATE VIEW dbo.vw_ClientesNivel
WITH SCHEMABINDING
AS
SELECT 
    c.ClienteID,
    c.Nombre,
    c.Apellido,
    c.Email,
    COUNT_BIG(*) AS TotalPedidos,
    SUM(ISNULL(p.Total, 0)) AS TotalGastado,
    MAX(p.FechaPedido) AS UltimoPedido
FROM dbo.Clientes c
INNER JOIN dbo.Pedidos p ON c.ClienteID = p.ClienteID
WHERE c.Activo = 1
GROUP BY c.ClienteID, c.Nombre, c.Apellido, c.Email;
GO

-- Crear índice único clustered en la vista indexada
CREATE UNIQUE CLUSTERED INDEX IX_vw_ClientesNivel
ON dbo.vw_ClientesNivel(ClienteID);
GO

-- ============================================================================
-- ÍNDICE 8: ÍNDICE PARA BÚSQUEDA DE PRODUCTOS
-- ============================================================================
-- Mejora: Consulta Lenta 9 - Búsqueda con wildcard

-- Índice full-text para búsquedas complejas (requiere configuración adicional)
-- Por ahora, índice tradicional en Nombre
CREATE NONCLUSTERED INDEX IX_Productos_Nombre
ON dbo.Productos(Nombre)
INCLUDE (Categoria, Precio, Descripcion);
GO

-- ============================================================================
-- ÍNDICE 9: ÍNDICES PARA ESTADÍSTICAS Y REPORTES
-- ============================================================================

-- Índice para reportes por estado de pedido
CREATE NONCLUSTERED INDEX IX_Pedidos_Estado
ON dbo.Pedidos(Estado)
INCLUDE (ClienteID, FechaPedido, Total);
GO

-- Índice para análisis de productos más vendidos
CREATE NONCLUSTERED INDEX IX_DetallePedidos_ProductoID_Cantidad
ON dbo.DetallePedidos(ProductoID)
INCLUDE (Cantidad, PedidoID, PrecioUnitario);
GO

-- ============================================================================
-- VERIFICACIÓN DE ÍNDICES CREADOS
-- ============================================================================

SELECT 
    t.name AS Tabla,
    i.name AS Indice,
    i.type_desc AS Tipo,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS Columnas
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE t.name IN ('Clientes', 'Productos', 'Pedidos', 'DetallePedidos')
  AND i.type_desc NOT IN ('HEAP')
GROUP BY t.name, i.name, i.type_desc
ORDER BY t.name, i.name;
GO

-- ============================================================================
-- ESTADÍSTICAS DE USO DE ÍNDICES
-- ============================================================================

SELECT 
    OBJECT_NAME(i.object_id) AS Tabla,
    i.name AS Indice,
    i.type_desc AS Tipo,
    s.user_seeks AS Busquedas,
    s.user_scans AS Escaneos,
    s.user_lookups AS Consultas,
    s.user_updates AS Actualizaciones,
    (s.user_seeks + s.user_scans + s.user_lookups) AS TotalLecturas
FROM sys.indexes i
INNER JOIN sys.dm_db_index_usage_stats s ON i.object_id = s.object_id AND i.index_id = s.index_id
WHERE OBJECT_NAME(i.object_id) IN ('Clientes', 'Productos', 'Pedidos', 'DetallePedidos')
ORDER BY TotalLecturas DESC;
GO

PRINT '=== ÍNDICES CREADOS EXITOSAMENTE ===';
PRINT 'Ejecute las consultas lentas nuevamente para comparar el rendimiento.';
GO
