-- ============================================================================
-- EJEMPLOS DE CONSULTAS LENTAS (SLOW QUERIES)
-- ============================================================================
-- Este script contiene consultas intencionalmente ineficientes para demostrar
-- problemas comunes de rendimiento y la necesidad de optimización.
-- ============================================================================

USE OptimizacionLab;
GO

-- ============================================================================
-- CONSULTA LENTA 1: BÚSQUEDA SIN ÍNDICE EN CAMPO NO INDEXADO
-- ============================================================================
-- Problema: Búsqueda por Email sin índice provoca table scan completo
-- Impacto: Escaneo de 100,000 registros para cada búsqueda

-- Esta consulta es LENTA porque no hay índice en la columna Email
SELECT ClienteID, Nombre, Apellido, Email, Telefono
FROM dbo.Clientes
WHERE Email LIKE '%gmail.com';
GO

-- ============================================================================
-- CONSULTA LENTA 2: JOIN MÚLTIPLE SIN ÍNDICES ADECUADOS
-- ============================================================================
-- Problema: Múltiples joins sin índices en las columnas de unión
-- Impacto: Hash joins costosos y posibles table scans

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
-- CONSULTA LENTA 3: AGREGACIÓN SOBRE TABLA GRANDE SIN ÍNDICE
-- ============================================================================
-- Problema: GROUP BY sobre columna no indexada
-- Impacto: Ordenamiento y agrupación costosa en memoria

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
-- CONSULTA LENTA 4: SUBCONSULTA CORRELACIONADA INEFICIENTE
-- ============================================================================
-- Problema: Subconsulta que se ejecuta por cada fila de la tabla externa
-- Impacto: Ejecución N+1 veces de la subconsulta

SELECT 
    c.ClienteID,
    c.Nombre + ' ' + c.Apellido AS Cliente,
    c.Email,
    (SELECT COUNT(*) FROM dbo.Pedidos p WHERE p.ClienteID = c.ClienteID) AS TotalPedidos,
    (SELECT SUM(Total) FROM dbo.Pedidos p WHERE p.ClienteID = c.ClienteID) AS TotalGastado,
    (SELECT MAX(FechaPedido) FROM dbo.Pedidos p WHERE p.ClienteID = c.ClienteID) AS UltimoPedido
FROM dbo.Clientes c
WHERE c.Activo = 1
ORDER BY TotalGastado DESC;
GO

-- ============================================================================
-- CONSULTA LENTA 5: USO DE FUNCIONES EN CLÁUSULA WHERE
-- ============================================================================
-- Problema: Aplicar funciones en columnas del WHERE impide uso de índices
-- Impacto: El índice no puede ser utilizado para la búsqueda

SELECT 
    PedidoID,
    ClienteID,
    FechaPedido,
    Total,
    Estado
FROM dbo.Pedidos
WHERE YEAR(FechaPedido) = 2025 
  AND MONTH(FechaPedido) = 1;
GO

-- ============================================================================
-- CONSULTA LENTA 6: DISTINCT INNecesARIO CON JOINS
-- ============================================================================
-- Problema: Uso de DISTINCT para eliminar duplicados de joins mal diseñados
-- Impacto: Ordenamiento adicional para eliminar duplicados

SELECT DISTINCT
    c.ClienteID,
    c.Nombre,
    c.Apellido,
    dp.ProductoID,
    pr.Nombre AS Producto
FROM dbo.Clientes c
INNER JOIN dbo.Pedidos p ON c.ClienteID = p.ClienteID
INNER JOIN dbo.DetallePedidos dp ON p.PedidoID = dp.PedidoID
INNER JOIN dbo.Productos pr ON dp.ProductoID = pr.ProductoID
WHERE p.Estado = 'Entregado';
GO

-- ============================================================================
-- CONSULTA LENTA 7: TABLA TEMPORAL SIN ÍNDICES
-- ============================================================================
-- Problema: Uso de tablas temporales sin índices para grandes volúmenes
-- Impacto: Operaciones lentas sobre datos temporales

IF OBJECT_ID('tempdb..#PedidosTemporales') IS NOT NULL
    DROP TABLE #PedidosTemporales;

CREATE TABLE #PedidosTemporales (
    PedidoID INT,
    ClienteID INT,
    FechaPedido DATETIME,
    Total DECIMAL(10,2),
    Estado NVARCHAR(50)
);

-- Insertar gran cantidad de datos
INSERT INTO #PedidosTemporales
SELECT * FROM dbo.Pedidos
WHERE Estado IN ('Pendiente', 'Procesando');

-- Consulta lenta sobre tabla temporal sin índice
SELECT 
    ClienteID,
    COUNT(*) AS CantidadPedidos,
    SUM(Total) AS TotalPendiente
FROM #PedidosTemporales
GROUP BY ClienteID
HAVING COUNT(*) > 5
ORDER BY TotalPendiente DESC;
GO

-- ============================================================================
-- CONSULTA LENTA 8: CURSOR EN LUGAR DE OPERACIÓN SET-BASED
-- ============================================================================
-- Problema: Uso de cursor para procesamiento fila por fila
-- Impacto: Overhead significativo comparado con operaciones set-based

DECLARE @ClienteID INT;
DECLARE @TotalGastado DECIMAL(10,2);
DECLARE @NivelCliente NVARCHAR(20);

DECLARE ClientesCursor CURSOR FOR
SELECT ClienteID FROM dbo.Clientes WHERE Activo = 1;

OPEN ClientesCursor;
FETCH NEXT FROM ClientesCursor INTO @ClienteID;

WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @TotalGastado = ISNULL(SUM(Total), 0)
    FROM dbo.Pedidos
    WHERE ClienteID = @ClienteID;
    
    IF @TotalGastado >= 10000
        SET @NivelCliente = 'VIP';
    ELSE IF @TotalGastado >= 5000
        SET @NivelCliente = 'Premium';
    ELSE IF @TotalGastado >= 1000
        SET @NivelCliente = 'Regular';
    ELSE
        SET @NivelCliente = 'Nuevo';
    
    -- Aquí iría un UPDATE, pero lo omitimos para no modificar datos
    
    FETCH NEXT FROM ClientesCursor INTO @ClienteID;
END

CLOSE ClientesCursor;
DEALLOCATE ClientesCursor;
GO

-- ============================================================================
-- CONSULTA LENTA 9: BÚSQUEDA CON WILDCARD AL INICIO
-- ============================================================================
-- Problema: LIKE con % al inicio impide uso de índices
-- Impacto: Table scan completo obligatorio

SELECT 
    ProductoID,
    Nombre,
    Categoria,
    Precio
FROM dbo.Productos
WHERE Nombre LIKE '%Premium%';
GO

-- ============================================================================
-- CONSULTA LENTA 10: MÚLTIPLES UNION ALL SIN FILTROS
-- ============================================================================
-- Problema: Unir múltiples resultados sin necesidad real
-- Impacto: Procesamiento innecesario de grandes volúmenes

SELECT Categoria, 'Rango 1' AS Rango, COUNT(*) AS Cantidad
FROM dbo.Productos WHERE Precio BETWEEN 0 AND 100
GROUP BY Categoria
UNION ALL
SELECT Categoria, 'Rango 2', COUNT(*)
FROM dbo.Productos WHERE Precio BETWEEN 101 AND 500
GROUP BY Categoria
UNION ALL
SELECT Categoria, 'Rango 3', COUNT(*)
FROM dbo.Productos WHERE Precio BETWEEN 501 AND 1000
GROUP BY Categoria
UNION ALL
SELECT Categoria, 'Rango 4', COUNT(*)
FROM dbo.Productos WHERE Precio > 1000
GROUP BY Categoria;
GO

-- ============================================================================
-- NOTA: Estas consultas están diseñadas para ser lentas intencionalmente.
-- En los scripts de índices se mostrará cómo optimizarlas.
-- ============================================================================

PRINT '=== CONSULTAS LENTAS EJECUTADAS ===';
PRINT 'Revise el execution plan para analizar el rendimiento.';
GO
