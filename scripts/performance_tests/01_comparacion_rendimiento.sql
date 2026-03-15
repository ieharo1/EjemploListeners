-- ============================================================================
-- PRUEBAS DE COMPARACIÓN DE RENDIMIENTO
-- ============================================================================
-- Este script permite comparar el rendimiento de consultas antes y después
-- de aplicar optimizaciones con índices.
-- ============================================================================

USE OptimizacionLab;
GO

-- ============================================================================
-- CONFIGURACIÓN DE ESTADÍSTICAS DE RENDIMIENTO
-- ============================================================================

SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

-- ============================================================================
-- PRUEBA 1: BÚSQUEDA DE CLIENTES POR EMAIL
-- ============================================================================

PRINT '========================================';
PRINT 'PRUEBA 1: Búsqueda por Email';
PRINT '========================================';

-- Versión SIN índice (si se eliminara temporalmente)
-- SELECT ClienteID, Nombre, Apellido, Email, Telefono
-- FROM dbo.Clientes
-- WHERE Email LIKE 'juan.garcia%';

-- Versión CON índice
SELECT ClienteID, Nombre, Apellido, Email, Telefono
FROM dbo.Clientes
WHERE Email LIKE 'juan.garcia%';
GO

-- ============================================================================
-- PRUEBA 2: CONSULTA DE PEDIDOS POR CLIENTE
-- ============================================================================

PRINT '========================================';
PRINT 'PRUEBA 2: Pedidos por Cliente con Fechas';
PRINT '========================================';

SELECT 
    c.ClienteID,
    c.Nombre + ' ' + c.Apellido AS Cliente,
    p.PedidoID,
    p.FechaPedido,
    p.Total,
    p.Estado
FROM dbo.Clientes c
INNER JOIN dbo.Pedidos p ON c.ClienteID = p.ClienteID
WHERE p.FechaPedido >= DATEADD(MONTH, -6, GETDATE())
ORDER BY p.FechaPedido DESC;
GO

-- ============================================================================
-- PRUEBA 3: ESTADÍSTICAS POR CATEGORÍA
-- ============================================================================

PRINT '========================================';
PRINT 'PRUEBA 3: Estadísticas por Categoría';
PRINT '========================================';

SELECT 
    Categoria,
    COUNT(*) AS CantidadProductos,
    AVG(Precio) AS PrecioPromedio,
    MIN(Precio) AS PrecioMinimo,
    MAX(Precio) AS PrecioMaximo,
    SUM(Stock) AS StockTotal
FROM dbo.Productos
GROUP BY Categoria
ORDER BY CantidadProductos DESC;
GO

-- ============================================================================
-- PRUEBA 4: TOTAL DE PEDIDOS POR CLIENTE (OPTIMIZADA)
-- ============================================================================

PRINT '========================================';
PRINT 'PRUEBA 4: Total de Pedidos por Cliente (Optimizada)';
PRINT '========================================';

-- Versión optimizada con JOIN en lugar de subconsultas correlacionadas
SELECT 
    c.ClienteID,
    c.Nombre + ' ' + c.Apellido AS Cliente,
    c.Email,
    COUNT(p.PedidoID) AS TotalPedidos,
    ISNULL(SUM(p.Total), 0) AS TotalGastado,
    MAX(p.FechaPedido) AS UltimoPedido
FROM dbo.Clientes c
LEFT JOIN dbo.Pedidos p ON c.ClienteID = p.ClienteID
WHERE c.Activo = 1
GROUP BY c.ClienteID, c.Nombre, c.Apellido, c.Email
ORDER BY TotalGastado DESC;
GO

-- ============================================================================
-- PRUEBA 5: BÚSQUEDA POR RANGO DE FECHAS (OPTIMIZADA)
-- ============================================================================

PRINT '========================================';
PRINT 'PRUEBA 5: Búsqueda por Rango de Fechas (Optimizada)';
PRINT '========================================';

-- Versión optimizada SIN funciones en WHERE
SELECT 
    PedidoID,
    ClienteID,
    FechaPedido,
    Total,
    Estado
FROM dbo.Pedidos
WHERE FechaPedido >= '2025-01-01' 
  AND FechaPedido < '2025-02-01';
GO

-- ============================================================================
-- PRUEBA 6: PRODUCTOS MÁS VENDIDOS
-- ============================================================================

PRINT '========================================';
PRINT 'PRUEBA 6: Productos Más Vendidos';
PRINT '========================================';

SELECT TOP 20
    pr.ProductoID,
    pr.Nombre AS Producto,
    pr.Categoria,
    SUM(dp.Cantidad) AS CantidadVendida,
    SUM(dp.Subtotal) AS TotalVentas,
    COUNT(DISTINCT dp.PedidoID) AS PedidosConProducto
FROM dbo.Productos pr
INNER JOIN dbo.DetallePedidos dp ON pr.ProductoID = dp.ProductoID
GROUP BY pr.ProductoID, pr.Nombre, pr.Categoria
ORDER BY CantidadVendida DESC;
GO

-- ============================================================================
-- PRUEBA 7: CLIENTES VIP (USANDO VISTA INDEXADA)
-- ============================================================================

PRINT '========================================';
PRINT 'PRUEBA 7: Clientes VIP (Vista Indexada)';
PRINT '========================================';

SELECT 
    ClienteID,
    Nombre + ' ' + Apellido AS Cliente,
    Email,
    TotalPedidos,
    TotalGastado,
    UltimoPedido,
    CASE 
        WHEN TotalGastado >= 10000 THEN 'VIP'
        WHEN TotalGastado >= 5000 THEN 'Premium'
        WHEN TotalGastado >= 1000 THEN 'Regular'
        ELSE 'Nuevo'
    END AS NivelCliente
FROM dbo.vw_ClientesNivel
WHERE TotalGastado >= 1000
ORDER BY TotalGastado DESC;
GO

-- ============================================================================
-- PRUEBA 8: ANÁLISIS DE VENTAS POR ESTADO
-- ============================================================================

PRINT '========================================';
PRINT 'PRUEBA 8: Ventas por Estado de Pedido';
PRINT '========================================';

SELECT 
    Estado,
    COUNT(*) AS CantidadPedidos,
    SUM(Total) AS TotalVentas,
    AVG(Total) AS PromedioVenta,
    MIN(Total) AS VentaMinima,
    MAX(Total) AS VentaMaxima
FROM dbo.Pedidos
GROUP BY Estado
ORDER BY TotalVentas DESC;
GO

-- ============================================================================
-- PRUEBA 9: TICKET PROMEDIO POR CATEGORÍA
-- ============================================================================

PRINT '========================================';
PRINT 'PRUEBA 9: Ticket Promedio por Categoría';
PRINT '========================================';

SELECT 
    pr.Categoria,
    COUNT(DISTINCT dp.PedidoID) AS PedidosUnicos,
    SUM(dp.Cantidad) AS ProductosVendidos,
    SUM(dp.Subtotal) AS VentasTotales,
    AVG(dp.Subtotal) AS TicketPromedio,
    CAST(AVG(dp.Subtotal) AS DECIMAL(10,2)) AS TicketPromedioRedondeado
FROM dbo.Productos pr
INNER JOIN dbo.DetallePedidos dp ON pr.ProductoID = dp.ProductoID
GROUP BY pr.Categoria
ORDER BY VentasTotales DESC;
GO

-- ============================================================================
-- PRUEBA 10: CLIENTES INACTIVOS CON PEDIDOS PENDIENTES
-- ============================================================================

PRINT '========================================';
PRINT 'PRUEBA 10: Clientes Inactivos con Pedidos Pendientes';
PRINT '========================================';

SELECT 
    c.ClienteID,
    c.Nombre + ' ' + c.Apellido AS Cliente,
    c.Email,
    COUNT(p.PedidoID) AS PedidosPendientes,
    SUM(p.Total) AS TotalPendiente
FROM dbo.Clientes c
INNER JOIN dbo.Pedidos p ON c.ClienteID = p.ClienteID
WHERE c.Activo = 0 
  AND p.Estado IN ('Pendiente', 'Procesando')
GROUP BY c.ClienteID, c.Nombre, c.Apellido, c.Email
ORDER BY TotalPendiente DESC;
GO

-- ============================================================================
-- LIMPIEZA DE ESTADÍSTICAS
-- ============================================================================

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- ============================================================================
-- RESUMEN DE ESTADÍSTICAS DE EJECUCIÓN
-- ============================================================================

PRINT '========================================';
PRINT 'RESUMEN DE ESTADÍSTICAS';
PRINT '========================================';
PRINT 'Las estadísticas de TIME muestran:';
PRINT '  - CPU Time: Tiempo de procesador utilizado';
PRINT '  - Elapsed Time: Tiempo total transcurrido';
PRINT '';
PRINT 'Las estadísticas de IO muestran:';
PRINT '  - Lecturas lógicas: Páginas leídas desde caché';
PRINT '  - Lecturas físicas: Páginas leídas desde disco';
PRINT '  - Lecturas anticipadas: Páginas leídas preventivamente';
PRINT '========================================';
GO
