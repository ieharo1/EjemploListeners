-- ============================================================================
-- GENERACIÓN DE DATOS MASIVOS PARA PRUEBAS DE RENDIMIENTO
-- ============================================================================
-- Este script genera grandes volúmenes de datos para simular escenarios reales
-- de producción y poder realizar pruebas de optimización.
-- ============================================================================

USE master;
GO

-- Crear base de datos para pruebas de rendimiento
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'OptimizacionLab')
BEGIN
    CREATE DATABASE OptimizacionLab;
    PRINT 'Base de datos OptimizacionLab creada exitosamente.';
END
GO

USE OptimizacionLab;
GO

-- ============================================================================
-- TABLA 1: CLIENTES (100,000 registros)
-- ============================================================================

IF OBJECT_ID('dbo.Clientes', 'U') IS NOT NULL
    DROP TABLE dbo.Clientes;
GO

CREATE TABLE dbo.Clientes (
    ClienteID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL,
    Apellido NVARCHAR(100) NOT NULL,
    Email NVARCHAR(255) NOT NULL,
    Telefono NVARCHAR(20),
    FechaRegistro DATETIME DEFAULT GETDATE(),
    Activo BIT DEFAULT 1
);
GO

-- Generar 100,000 clientes de prueba
DECLARE @i INT = 1;
DECLARE @Nombres TABLE (Nombre NVARCHAR(50));
DECLARE @Apellidos TABLE (Apellido NVARCHAR(50));

-- Insertar nombres de ejemplo
INSERT INTO @Nombres VALUES 
    ('Juan'), ('María'), ('Carlos'), ('Ana'), ('Luis'), 
    ('Pedro'), ('Laura'), ('José'), ('Carmen'), ('Miguel');

INSERT INTO @Apellidos VALUES 
    ('García'), ('Rodríguez'), ('Martínez'), ('López'), ('González'),
    ('Hernández'), ('Pérez'), ('Sánchez'), ('Ramírez'), ('Torres');

WHILE @i <= 100000
BEGIN
    INSERT INTO dbo.Clientes (Nombre, Apellido, Email, Telefono, FechaRegistro, Activo)
    SELECT 
        N.Nombre,
        A.Apellido,
        LOWER(N.Nombre) + '.' + LOWER(A.Apellido) + CAST(@i AS NVARCHAR) + '@email.com',
        '(' + CAST(ABS(CHECKSUM(NEWID()) % 900 + 10) AS NVARCHAR) + ') ' + 
            CAST(ABS(CHECKSUM(NEWID()) % 9000 + 1000) AS NVARCHAR) + '-' + 
            CAST(ABS(CHECKSUM(NEWID()) % 9000 + 1000) AS NVARCHAR),
        DATEADD(DAY, -ABS(CHECKSUM(NEWID()) % 1000), GETDATE()),
        CASE WHEN ABS(CHECKSUM(NEWID()) % 10) < 9 THEN 1 ELSE 0 END
    FROM @Nombres N
    CROSS JOIN @Apellidos A
    WHERE @i <= 100000;
    
    SET @i = @i + 1;
    
    -- Salir cuando alcanzamos el límite
    IF (SELECT COUNT(*) FROM dbo.Clientes) >= 100000
        BREAK;
END
GO

PRINT 'Clientes generados: ' + CAST((SELECT COUNT(*) FROM dbo.Clientes) AS NVARCHAR);
GO

-- ============================================================================
-- TABLA 2: PRODUCTOS (10,000 registros)
-- ============================================================================

IF OBJECT_ID('dbo.Productos', 'U') IS NOT NULL
    DROP TABLE dbo.Productos;
GO

CREATE TABLE dbo.Productos (
    ProductoID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(200) NOT NULL,
    Descripcion NVARCHAR(500),
    Categoria NVARCHAR(100),
    Precio DECIMAL(10,2) NOT NULL,
    Stock INT DEFAULT 0,
    FechaCreacion DATETIME DEFAULT GETDATE()
);
GO

-- Generar 10,000 productos
DECLARE @j INT = 1;
DECLARE @Categorias TABLE (Categoria NVARCHAR(50));

INSERT INTO @Categorias VALUES 
    ('Electrónica'), ('Ropa'), ('Hogar'), ('Deportes'), ('Juguetes'),
    ('Libros'), ('Alimentos'), ('Belleza'), ('Automóvil'), ('Oficina');

WHILE @j <= 10000
BEGIN
    INSERT INTO dbo.Productos (Nombre, Descripcion, Categoria, Precio, Stock, FechaCreacion)
    SELECT 
        'Producto ' + CAST(@j AS NVARCHAR) + ' - ' + C.Categoria,
        'Descripción detallada del producto ' + CAST(@j AS NVARCHAR) + 
            '. Este es un ejemplo de descripción extensa para pruebas de rendimiento.',
        C.Categoria,
        CAST(ABS(CHECKSUM(NEWID()) % 10000) + 10.00 AS DECIMAL(10,2)),
        ABS(CHECKSUM(NEWID()) % 1000),
        DATEADD(DAY, -ABS(CHECKSUM(NEWID()) % 500), GETDATE())
    FROM @Categorias C
    WHERE @j <= 10000;
    
    SET @j = @j + 1;
    
    IF (SELECT COUNT(*) FROM dbo.Productos) >= 10000
        BREAK;
END
GO

PRINT 'Productos generados: ' + CAST((SELECT COUNT(*) FROM dbo.Productos) AS NVARCHAR);
GO

-- ============================================================================
-- TABLA 3: PEDIDOS (500,000 registros)
-- ============================================================================

IF OBJECT_ID('dbo.Pedidos', 'U') IS NOT NULL
    DROP TABLE dbo.Pedidos;
GO

CREATE TABLE dbo.Pedidos (
    PedidoID INT IDENTITY(1,1) PRIMARY KEY,
    ClienteID INT NOT NULL,
    FechaPedido DATETIME DEFAULT GETDATE(),
    Total DECIMAL(10,2),
    Estado NVARCHAR(50) DEFAULT 'Pendiente',
    FOREIGN KEY (ClienteID) REFERENCES dbo.Clientes(ClienteID)
);
GO

-- Crear índice para acelerar la generación
CREATE NONCLUSTERED INDEX IX_Pedidos_ClienteID ON dbo.Pedidos(ClienteID);
GO

-- Generar 500,000 pedidos
DECLARE @k INT = 1;
DECLARE @Estados TABLE (Estado NVARCHAR(50));

INSERT INTO @Estados VALUES 
    ('Pendiente'), ('Procesando'), ('Enviado'), ('Entregado'), ('Cancelado');

WHILE @k <= 500000
BEGIN
    INSERT INTO dbo.Pedidos (ClienteID, FechaPedido, Total, Estado)
    SELECT TOP 10000
        ABS(CHECKSUM(NEWID()) % (SELECT COUNT(*) FROM dbo.Clientes)) + 1,
        DATEADD(HOUR, -ABS(CHECKSUM(NEWID()) % 8760), GETDATE()),
        CAST(ABS(CHECKSUM(NEWID()) % 5000) + 50.00 AS DECIMAL(10,2)),
        E.Estado
    FROM @Estados E
    CROSS JOIN (SELECT TOP 1000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N FROM sys.objects) AS Numbers;
    
    SET @k = @k + 10000;
    
    IF (SELECT COUNT(*) FROM dbo.Pedidos) >= 500000
        BREAK;
END
GO

PRINT 'Pedidos generados: ' + CAST((SELECT COUNT(*) FROM dbo.Pedidos) AS NVARCHAR);
GO

-- ============================================================================
-- TABLA 4: DETALLE PEDIDOS (1,500,000 registros)
-- ============================================================================

IF OBJECT_ID('dbo.DetallePedidos', 'U') IS NOT NULL
    DROP TABLE dbo.DetallePedidos;
GO

CREATE TABLE dbo.DetallePedidos (
    DetalleID INT IDENTITY(1,1) PRIMARY KEY,
    PedidoID INT NOT NULL,
    ProductoID INT NOT NULL,
    Cantidad INT NOT NULL,
    PrecioUnitario DECIMAL(10,2) NOT NULL,
    Subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (PedidoID) REFERENCES dbo.Pedidos(PedidoID),
    FOREIGN KEY (ProductoID) REFERENCES dbo.Productos(ProductoID)
);
GO

-- Generar detalles de pedidos (3 productos por pedido en promedio)
INSERT INTO dbo.DetallePedidos (PedidoID, ProductoID, Cantidad, PrecioUnitario, Subtotal)
SELECT TOP 1500000
    ABS(CHECKSUM(NEWID()) % (SELECT COUNT(*) FROM dbo.Pedidos)) + 1,
    ABS(CHECKSUM(NEWID()) % (SELECT COUNT(*) FROM dbo.Productos)) + 1,
    ABS(CHECKSUM(NEWID()) % 10) + 1,
    CAST(ABS(CHECKSUM(NEWID()) % 1000) + 10.00 AS DECIMAL(10,2)),
    0 -- Se actualizará después
FROM sys.objects o1
CROSS JOIN sys.objects o2
CROSS JOIN sys.objects o3;
GO

-- Actualizar subtotales
UPDATE dbo.DetallePedidos
SET Subtotal = Cantidad * PrecioUnitario;
GO

PRINT 'Detalles de pedidos generados: ' + CAST((SELECT COUNT(*) FROM dbo.DetallePedidos) AS NVARCHAR);
GO

-- ============================================================================
-- RESUMEN DE DATOS GENERADOS
-- ============================================================================

SELECT 
    'Clientes' AS Tabla, COUNT(*) AS Registros FROM dbo.Clientes
UNION ALL
SELECT 
    'Productos', COUNT(*) FROM dbo.Productos
UNION ALL
SELECT 
    'Pedidos', COUNT(*) FROM dbo.Pedidos
UNION ALL
SELECT 
    'DetallePedidos', COUNT(*) FROM dbo.DetallePedidos;
GO

-- ============================================================================
-- ESTADÍSTICAS DE LA BASE DE DATOS
-- ============================================================================

EXEC sp_spaceused;
GO

PRINT '=== GENERACIÓN DE DATOS COMPLETADA ===';
PRINT 'Base de datos lista para pruebas de optimización.';
GO
