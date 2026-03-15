-- ============================================================================
-- EJEMPLOS DE EXECUTION PLAN (PLAN DE EJECUCIÓN)
-- ============================================================================
-- Este script contiene consultas diseñadas para analizar diferentes tipos
-- de planes de ejecución en SQL Server.
-- ============================================================================

USE OptimizacionLab;
GO

-- ============================================================================
-- NOTA: Para ver el execution plan:
-- 1. En SSMS: Ctrl+L (plan estimado) o Ctrl+M (plan real)
-- 2. Analizar operadores costosos
-- 3. Identificar Table Scan, Index Scan, Index Seek, etc.
-- ============================================================================

-- ============================================================================
-- EJEMPLO 1: TABLE SCAN vs INDEX SEEK
-- ============================================================================
-- TABLE SCAN: Escanea toda la tabla (costoso)
-- INDEX SEEK: Busca directamente en el índice (eficiente)

-- Consulta que probablemente use TABLE SCAN sin índice adecuado
SELECT * FROM dbo.Clientes WHERE Apellido = 'García';

-- Consulta que debería usar INDEX SEEK con el índice adecuado
SELECT ClienteID, Nombre, Apellido, Email 
FROM dbo.Clientes 
WHERE Apellido = 'García';
GO

-- ============================================================================
-- EJEMPLO 2: INDEX SCAN vs INDEX SEEK
-- ============================================================================
-- INDEX SCAN: Escanea todo el índice
-- INDEX SEEK: Busca específica en el índice

-- INDEX SCAN - cuando se seleccionan muchas columnas
SELECT * FROM dbo.Productos WHERE Categoria = 'Electrónica';

-- INDEX SEEK - cuando el índice cubre la consulta
SELECT ProductoID, Nombre, Precio 
FROM dbo.Productos 
WHERE Categoria = 'Electrónica';
GO

-- ============================================================================
-- EJEMPLO 3: HASH JOIN vs NESTED LOOPS vs MERGE JOIN
-- ============================================================================

-- HASH JOIN - común en grandes volúmenes sin índices
SELECT c.Nombre, p.PedidoID, p.Total
FROM dbo.Clientes c
JOIN dbo.Pedidos p ON c.ClienteID = p.ClienteID
OPTION (HASH JOIN);

-- NESTED LOOPS - eficiente para pequeños volúmenes
SELECT c.Nombre, p.PedidoID, p.Total
FROM dbo.Clientes c
JOIN dbo.Pedidos p ON c.ClienteID = p.ClienteID
OPTION (LOOP JOIN);

-- MERGE JOIN - requiere datos ordenados
SELECT c.Nombre, p.PedidoID, p.Total
FROM dbo.Clientes c
JOIN dbo.Pedidos p ON c.ClienteID = p.ClienteID
OPTION (MERGE JOIN);
GO

-- ============================================================================
-- EJEMPLO 4: SORT OPERATOR (ORDENAMIENTO COSTOSO)
-- ============================================================================
-- El operador Sort consume mucha memoria cuando hay muchos datos

SELECT 
    c.ClienteID,
    c.Nombre,
    SUM(p.Total) AS TotalGastado
FROM dbo.Clientes c
JOIN dbo.Pedidos p ON c.ClienteID = p.ClienteID
GROUP BY c.ClienteID, c.Nombre
ORDER BY TotalGastado DESC;
GO

-- ============================================================================
-- EJEMPLO 5: AGGREGATE OPERATOR (AGREGACIÓN)
-- ============================================================================

SELECT 
    Categoria,
    COUNT(*) AS Cantidad,
    AVG(Precio) AS Promedio
FROM dbo.Productos
GROUP BY Categoria;
GO

-- ============================================================================
-- EJEMPLO 6: KEY LOOKUP (BÚSQUEDA ADICIONAL)
-- ============================================================================
-- Key Lookup ocurre cuando el índice no cubre todas las columnas

-- Esto genera KEY LOOKUP porque faltan columnas en el índice
SELECT ClienteID, Nombre, Apellido, Email, Telefono, FechaRegistro
FROM dbo.Clientes
WHERE Apellido = 'García';
GO

-- ============================================================================
-- EJEMPLO 7: RID LOOKUP (EN HEAP - TABLA SIN CLUSTERED INDEX)
-- ============================================================================

-- Si la tabla no tiene clustered index, se produce RID Lookup
-- Verificar si la tabla tiene clustered index
SELECT 
    t.name AS Tabla,
    i.type_desc AS TipoIndex
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id
WHERE t.name = 'Clientes' AND i.type = 1; -- Clustered
GO

-- ============================================================================
-- EJEMPLO 8: PARAMETER SNIFFING
-- ============================================================================
-- El plan se compila con los primeros parámetros y puede no ser óptimo

CREATE PROCEDURE sp_BuscarPedidosPorEstado
    @Estado NVARCHAR(50)
AS
BEGIN
    SELECT 
        p.PedidoID,
        c.Nombre AS Cliente,
        p.FechaPedido,
        p.Total
    FROM dbo.Pedidos p
    JOIN dbo.Clientes c ON p.ClienteID = c.ClienteID
    WHERE p.Estado = @Estado;
END
GO

-- Ejecutar con diferentes parámetros para ver efecto de parameter sniffing
EXEC sp_BuscarPedidosPorEstado @Estado = 'Entregado';
EXEC sp_BuscarPedidosPorEstado @Estado = 'Pendiente';
GO

-- Solución: Usar OPTION (RECOMPILE)
CREATE PROCEDURE sp_BuscarPedidosPorEstado_Optimizado
    @Estado NVARCHAR(50)
AS
BEGIN
    SELECT 
        p.PedidoID,
        c.Nombre AS Cliente,
        p.FechaPedido,
        p.Total
    FROM dbo.Pedidos p
    JOIN dbo.Clientes c ON p.ClienteID = c.ClienteID
    WHERE p.Estado = @Estado
    OPTION (RECOMPILE);
END
GO

-- ============================================================================
-- EJEMPLO 9: OPERADOR DE FILTRADO (FILTER)
-- ============================================================================

SELECT 
    PedidoID,
    ClienteID,
    Total,
    Estado
FROM dbo.Pedidos
WHERE Total > 1000 AND Estado = 'Entregado';
GO

-- ============================================================================
-- EJEMPLO 10: COMPUTED SCALAR (CÁLCULOS EN CONSULTA)
-- ============================================================================

SELECT 
    PedidoID,
    Total,
    Total * 0.16 AS IVA,
    Total * 1.16 AS TotalConIVA
FROM dbo.Pedidos;
GO

-- ============================================================================
-- EJEMPLO 11: ANALIZAR COSTO RELATIVO DE OPERADORES
-- ============================================================================
-- En el execution plan, el % de costo indica qué operador consume más recursos

SELECT TOP 10
    c.ClienteID,
    c.Nombre,
    COUNT(p.PedidoID) AS Pedidos,
    SUM(dp.Cantidad) AS Productos,
    SUM(p.Total) AS TotalGastado
FROM dbo.Clientes c
JOIN dbo.Pedidos p ON c.ClienteID = p.ClienteID
JOIN dbo.DetallePedidos dp ON p.PedidoID = dp.PedidoID
WHERE p.Estado = 'Entregado'
GROUP BY c.ClienteID, c.Nombre
ORDER BY TotalGastado DESC;
GO

-- ============================================================================
-- EJEMPLO 12: FORZAR USO DE ÍNDICE ESPECÍFICO
-- ============================================================================
-- En casos específicos, podemos forzar el uso de un índice

SELECT 
    p.PedidoID,
    p.FechaPedido,
    p.Total
FROM dbo.Pedidos p WITH (INDEX(IX_Pedidos_FechaPedido))
WHERE p.FechaPedido >= DATEADD(MONTH, -1, GETDATE());
GO

-- ============================================================================
-- EJEMPLO 13: IDENTIFICAR MISSING INDEX (ÍNDICES FALTANTES)
-- ============================================================================
-- SQL Server sugiere índices faltantes en el execution plan

-- Esta consulta puede generar sugerencias de índices faltantes
SELECT 
    c.Nombre,
    p.FechaPedido,
    dp.Cantidad,
    pr.Nombre AS Producto
FROM dbo.Clientes c
JOIN dbo.Pedidos p ON c.ClienteID = p.ClienteID
JOIN dbo.DetallePedidos dp ON p.PedidoID = dp.PedidoID
JOIN dbo.Productos pr ON dp.ProductoID = pr.ProductoID
WHERE p.FechaPedido >= DATEADD(WEEK, -4, GETDATE());
GO

-- ============================================================================
-- CONSULTAR SUGERENCIAS DE ÍNDICES FALTANTES
-- ============================================================================

SELECT 
    dm_mid.database_id,
    dm_migs.avg_user_impact * (dm_migs.user_seeks + dm_migs.user_scans) AS ImprovementMeasure,
    'CREATE INDEX [missing_index_' + CONVERT (varchar, dm_mid.index_group_handle) + 
    '_' + CONVERT (varchar, dm_mid.index_handle) + '_' + 
    LEFT (PARSENAME(dm_mid.statement, 1), 32) + ']'
    + ' ON ' + dm_mid.statement
    + ' (' + ISNULL (dm_migs.equality_columns,'')
    + CASE WHEN dm_migs.equality_columns IS NOT NULL 
            AND dm_migs.inequality_columns IS NOT NULL THEN ',' ELSE '' END
    + ISNULL (dm_migs.inequality_columns, '')
    + ')'
    + ISNULL (' INCLUDE (' + dm_migs.included_columns + ')', '') AS CreateIndexStatement
FROM sys.dm_db_missing_index_groups dm_mig
INNER JOIN sys.dm_db_missing_index_group_stats dm_migs 
    ON dm_migs.group_handle = dm_mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details dm_mid 
    ON dm_mig.index_handle = dm_mid.index_handle
WHERE dm_mid.database_id = DB_ID()
ORDER BY ImprovementMeasure DESC;
GO

-- ============================================================================
-- EJEMPLO 14: ESTADÍSTICAS DE EJECUCIÓN EN CACHE
-- ============================================================================

SELECT 
    qs.execution_count,
    qs.total_worker_time / qs.execution_count AS avg_cpu_time,
    qs.total_elapsed_time / qs.execution_count AS avg_elapsed_time,
    qs.total_logical_reads / qs.execution_count AS avg_logical_reads,
    SUBSTRING(qt.text, (qs.statement_start_offset/2)+1, 
        ((CASE qs.statement_end_offset
          WHEN -1 THEN DATALENGTH(qt.text)
          ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2)+1) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
WHERE qt.dbid = DB_ID('OptimizacionLab')
ORDER BY qs.total_worker_time DESC;
GO

PRINT '=== EJEMPLOS DE EXECUTION PLAN COMPLETADOS ===';
PRINT 'Use Ctrl+L en SSMS para ver el plan de ejecución estimado.';
GO
