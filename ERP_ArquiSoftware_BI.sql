-- ============================================================
--  ERP_ArquiSoftware  –  Script BD optimizado para BI
--  Motor: MySQL 8.0+
--  Versión BI: incluye campos auditables, tablas de dimensión,
--  tablas de hechos ETL y vistas para KPIs.
-- ============================================================

CREATE DATABASE IF NOT EXISTS ERP_ArquiSoftware
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE ERP_ArquiSoftware;

-- ============================================================
--  1. TABLAS BASE
-- ============================================================

CREATE TABLE Categorias (
    Id          INT AUTO_INCREMENT PRIMARY KEY,
    Nombre      VARCHAR(100)  NOT NULL,
    Descripcion VARCHAR(255)  NULL,
    -- [BI] Para agrupar en jerarquías de producto
    CategoriaPadreId INT NULL,
    CONSTRAINT FK_Categorias_Padre FOREIGN KEY (CategoriaPadreId) REFERENCES Categorias(Id)
);

CREATE TABLE Marcas (
    Id     INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    -- [BI] País de origen útil para análisis geográfico de proveeduría
    PaisOrigen VARCHAR(100) NULL
);

CREATE TABLE UnidadesMedida (
    Id     INT AUTO_INCREMENT PRIMARY KEY,
    Codigo VARCHAR(20)  NOT NULL,
    Nombre VARCHAR(100) NOT NULL
);

CREATE TABLE Impuestos (
    Id         INT AUTO_INCREMENT PRIMARY KEY,
    Nombre     VARCHAR(100) NOT NULL,
    Porcentaje DECIMAL(5,2) NOT NULL DEFAULT 0
);

CREATE TABLE Almacenes (
    Id        INT AUTO_INCREMENT PRIMARY KEY,
    Codigo    VARCHAR(20)  NOT NULL,
    Nombre    VARCHAR(150) NOT NULL,
    Ubicacion VARCHAR(255) NULL,
    -- [BI] Ciudad y tipo de almacén para análisis regional
    Ciudad    VARCHAR(100) NULL,
    Tipo      VARCHAR(50)  NULL,   -- 'PRINCIPAL','SECUNDARIO','CONSIGNACION'
    Activo    TINYINT(1)   NOT NULL DEFAULT 1
);

CREATE TABLE Proveedores (
    Id          INT AUTO_INCREMENT PRIMARY KEY,
    RazonSocial VARCHAR(200) NOT NULL,
    NIT         VARCHAR(20)  NOT NULL,
    Telefono    VARCHAR(30)  NULL,
    Email       VARCHAR(150) NULL,
    Direccion   VARCHAR(255) NULL,
    -- [BI] Ciudad y país para KPIs de diversificación geográfica de proveedores
    Ciudad      VARCHAR(100) NULL,
    Pais        VARCHAR(100) NULL DEFAULT 'Colombia',
    -- [BI] Clasificación para análisis de riesgo de proveedor
    Clasificacion VARCHAR(30) NULL,  -- 'A','B','C'
    FechaVinculacion DATE NULL,
    Activo      TINYINT(1)   NOT NULL DEFAULT 1,
    CONSTRAINT UQ_Proveedores_NIT UNIQUE (NIT)
);

CREATE TABLE CondicionesPago (
    Id          INT AUTO_INCREMENT PRIMARY KEY,
    Nombre      VARCHAR(100) NOT NULL,
    DiasCredito INT          NOT NULL DEFAULT 0
);

CREATE TABLE TiposContrato (
    Id          INT AUTO_INCREMENT PRIMARY KEY,
    Nombre      VARCHAR(100) NOT NULL,
    Descripcion VARCHAR(255) NULL
);

CREATE TABLE Departamentos (
    Id     INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    -- [BI] Centro de costo para KPIs de nómina por área
    CentroCosto VARCHAR(20) NULL
);

CREATE TABLE Cargos (
    Id             INT AUTO_INCREMENT PRIMARY KEY,
    Nombre         VARCHAR(100)  NOT NULL,
    SalarioBase    DECIMAL(18,2) NOT NULL DEFAULT 0,
    DepartamentoId INT           NULL,
    -- [BI] Nivel jerárquico para análisis de estructura organizacional
    NivelJerarquico INT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Cargos_Departamento FOREIGN KEY (DepartamentoId) REFERENCES Departamentos(Id)
);

CREATE TABLE SecuenciasDocumento (
    Id           INT AUTO_INCREMENT PRIMARY KEY,
    TipoDoc      VARCHAR(50) NOT NULL,
    Serie        VARCHAR(10) NOT NULL,
    UltimoNumero INT         NOT NULL DEFAULT 0,
    Prefijo      VARCHAR(10) NULL
);

CREATE TABLE ParametrosNomina (
    Id                          INT AUTO_INCREMENT PRIMARY KEY,
    Anio                        INT           NOT NULL,
    SMMLV                       DECIMAL(18,2) NOT NULL,
    AuxilioTransporte           DECIMAL(18,2) NOT NULL,
    TopeAuxTranspMultiplo       INT           NOT NULL DEFAULT 2,
    SaludEmpleadoPorc           DECIMAL(6,4)  NOT NULL,
    PensionEmpleadoPorc         DECIMAL(6,4)  NOT NULL,
    CesantiasPorc               DECIMAL(6,4)  NOT NULL,
    InteresesCesantiasAnualPorc DECIMAL(6,4)  NOT NULL,
    PrimaPorc                   DECIMAL(6,4)  NOT NULL,
    VacacionesPorc              DECIMAL(6,4)  NOT NULL,
    DiasMes                     INT           NOT NULL DEFAULT 30,
    Activo                      TINYINT(1)    NOT NULL DEFAULT 1
);

INSERT INTO ParametrosNomina
    (Anio, SMMLV, AuxilioTransporte, TopeAuxTranspMultiplo,
     SaludEmpleadoPorc, PensionEmpleadoPorc, CesantiasPorc,
     InteresesCesantiasAnualPorc, PrimaPorc, VacacionesPorc, DiasMes, Activo)
VALUES
    (2026, 1300000.00, 162000.00, 2,
     0.0400, 0.0400, 0.0833,
     0.1200, 0.0833, 0.0417, 30, 1);

-- ============================================================
--  2. PRODUCTOS
-- ============================================================

CREATE TABLE Productos (
    Id             INT AUTO_INCREMENT PRIMARY KEY,
    NombreProducto VARCHAR(200)  NOT NULL,
    Sku            VARCHAR(50)   NOT NULL,
    Gtin           VARCHAR(50)   NULL,
    Descripcion    VARCHAR(500)  NULL,
    CategoriaId    INT           NOT NULL,
    MarcaId        INT           NULL,
    UnidadMedidaId INT           NULL,
    ImpuestoId     INT           NULL,
    PrecioUnitario DECIMAL(18,2) NOT NULL DEFAULT 0,
    CostoEstandar  DECIMAL(18,2) NOT NULL DEFAULT 0,
    CostoPromedio  DECIMAL(18,2) NOT NULL DEFAULT 0,
    UltimoCosto    DECIMAL(18,2) NOT NULL DEFAULT 0,
    StockMinimo    DECIMAL(18,4) NOT NULL DEFAULT 0,
    -- [BI] Stock máximo para calcular KPI de nivel de servicio
    StockMaximo    DECIMAL(18,4) NOT NULL DEFAULT 0,
    -- [BI] Punto de reorden para análisis de quiebres de stock
    PuntoReorden   DECIMAL(18,4) NOT NULL DEFAULT 0,
    -- [BI] Fecha de último movimiento para análisis de productos sin rotación
    FechaUltimoMovimiento DATE NULL,
    Activo         TINYINT(1)    NOT NULL DEFAULT 1,
    -- [BI] Fecha de creación para análisis de incorporación de SKUs
    FechaCreacion  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT UQ_Productos_Sku UNIQUE (Sku),
    CONSTRAINT FK_Productos_Categoria   FOREIGN KEY (CategoriaId)    REFERENCES Categorias(Id),
    CONSTRAINT FK_Productos_Marca       FOREIGN KEY (MarcaId)        REFERENCES Marcas(Id),
    CONSTRAINT FK_Productos_Unidad      FOREIGN KEY (UnidadMedidaId) REFERENCES UnidadesMedida(Id),
    CONSTRAINT FK_Productos_Impuesto    FOREIGN KEY (ImpuestoId)     REFERENCES Impuestos(Id)
);
CREATE INDEX IX_Productos_Nombre ON Productos(NombreProducto);
CREATE INDEX IX_Productos_Gtin   ON Productos(Gtin);
CREATE INDEX IX_Productos_FechaUltimoMov ON Productos(FechaUltimoMovimiento);

-- ============================================================
--  3. PRODUCTO ↔ PROVEEDOR (histórico)
-- ============================================================

CREATE TABLE ProductoProveedores (
    ProductoId           INT           NOT NULL,
    ProveedorId          INT           NOT NULL,
    FechaDesde           DATE          NOT NULL,
    PrecioCompra         DECIMAL(18,2) NOT NULL DEFAULT 0,
    SkuProveedor         VARCHAR(50)   NULL,
    EsProveedorPrincipal TINYINT(1)    NOT NULL DEFAULT 0,
    -- [BI] Lead time en días para KPI de tiempo de reposición
    LeadTimeDias         INT           NOT NULL DEFAULT 0,
    PRIMARY KEY (ProductoId, ProveedorId, FechaDesde),
    CONSTRAINT FK_ProdProv_Producto  FOREIGN KEY (ProductoId)  REFERENCES Productos(Id)  ON DELETE CASCADE,
    CONSTRAINT FK_ProdProv_Proveedor FOREIGN KEY (ProveedorId) REFERENCES Proveedores(Id) ON DELETE CASCADE
);
CREATE INDEX IX_ProdProv_Principal ON ProductoProveedores(ProductoId, EsProveedorPrincipal);
CREATE INDEX IX_ProdProv_Sku       ON ProductoProveedores(SkuProveedor);

-- ============================================================
--  4. EXISTENCIAS (stock por almacén)
-- ============================================================

CREATE TABLE Existencias (
    ProductoId INT           NOT NULL,
    AlmacenId  INT           NOT NULL,
    Cantidad   DECIMAL(18,4) NOT NULL DEFAULT 0,
    -- [BI] Fecha de última actualización para análisis de frescura de stock
    FechaActualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (ProductoId, AlmacenId),
    CONSTRAINT FK_Exist_Producto FOREIGN KEY (ProductoId) REFERENCES Productos(Id)  ON DELETE CASCADE,
    CONSTRAINT FK_Exist_Almacen  FOREIGN KEY (AlmacenId)  REFERENCES Almacenes(Id)  ON DELETE CASCADE
);

-- ============================================================
--  5. MOVIMIENTOS DE INVENTARIO (Kardex)
-- ============================================================

CREATE TABLE MovimientosInventario (
    Id             INT AUTO_INCREMENT PRIMARY KEY,
    AlmacenId      INT           NOT NULL,
    ProductoId     INT           NOT NULL,
    Fecha          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    TipoMovimiento VARCHAR(30)   NOT NULL,  -- 'ENTRADA','SALIDA','TRASLADO','AJUSTE'
    Cantidad       DECIMAL(18,4) NOT NULL,
    CostoUnitario  DECIMAL(18,2) NULL,
    -- [BI] Importe total del movimiento para análisis de valor de inventario
    ImporteTotal   DECIMAL(18,2) GENERATED ALWAYS AS (Cantidad * CostoUnitario) STORED,
    Referencia     VARCHAR(100)  NULL,
    -- [BI] Tipo de documento origen para trazabilidad ETL
    TipoDocOrigen  VARCHAR(30)   NULL,  -- 'FACTURA_COMPRA','FACTURA_VENTA','PEDIDO','AJUSTE'
    Observacion    VARCHAR(300)  NULL,
    CONSTRAINT FK_MovInv_Almacen  FOREIGN KEY (AlmacenId)  REFERENCES Almacenes(Id),
    CONSTRAINT FK_MovInv_Producto FOREIGN KEY (ProductoId) REFERENCES Productos(Id)
);
CREATE INDEX IX_MovInv_Almacen_Producto_Fecha ON MovimientosInventario(AlmacenId, ProductoId, Fecha);
CREATE INDEX IX_MovInv_Fecha ON MovimientosInventario(Fecha);
CREATE INDEX IX_MovInv_TipoMovimiento ON MovimientosInventario(TipoMovimiento);

-- ============================================================
--  6. CLIENTES
-- ============================================================

CREATE TABLE Clientes (
    Id              INT AUTO_INCREMENT PRIMARY KEY,
    RazonSocial     VARCHAR(200) NOT NULL,
    TipoDocumento   VARCHAR(20)  NOT NULL,
    NumeroDocumento VARCHAR(30)  NOT NULL,
    Telefono        VARCHAR(30)  NULL,
    Email           VARCHAR(150) NULL,
    -- [BI] Segmentación de cliente para análisis de rentabilidad por segmento
    Segmento        VARCHAR(50)  NULL,  -- 'CORPORATIVO','PYME','PERSONA_NATURAL'
    -- [BI] Ciudad y región para KPIs geográficos de ventas
    Ciudad          VARCHAR(100) NULL,
    Departamento    VARCHAR(100) NULL,
    -- [BI] Fecha de vinculación para análisis de retención y churn
    FechaVinculacion DATE        NULL,
    -- [BI] Canal de adquisición
    CanalAdquisicion VARCHAR(50) NULL,  -- 'DIGITAL','REFERIDO','FUERZA_VENTA'
    Activo          TINYINT(1)   NOT NULL DEFAULT 1,
    CondicionPagoId INT          NULL,
    CONSTRAINT UQ_Clientes_Doc    UNIQUE (TipoDocumento, NumeroDocumento),
    CONSTRAINT FK_Clientes_Condicion FOREIGN KEY (CondicionPagoId) REFERENCES CondicionesPago(Id)
);
CREATE INDEX IX_Clientes_Segmento ON Clientes(Segmento);
CREATE INDEX IX_Clientes_Ciudad ON Clientes(Ciudad, Departamento);

CREATE TABLE DireccionesCliente (
    Id           INT AUTO_INCREMENT PRIMARY KEY,
    ClienteId    INT          NOT NULL,
    Descripcion  VARCHAR(100) NULL,
    Direccion    VARCHAR(255) NOT NULL,
    Ciudad       VARCHAR(100) NULL,
    Departamento VARCHAR(100) NULL,
    Principal    TINYINT(1)   NOT NULL DEFAULT 0,
    CONSTRAINT FK_DirCliente_Cliente FOREIGN KEY (ClienteId) REFERENCES Clientes(Id) ON DELETE CASCADE
);

-- ============================================================
--  7. PEDIDOS DE VENTA
-- ============================================================

CREATE TABLE PedidosVenta (
    Id              INT AUTO_INCREMENT PRIMARY KEY,
    Serie           VARCHAR(10)   NOT NULL,
    Numero          INT           NOT NULL,
    Fecha           DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- [BI] Fecha prometida de entrega para KPI de cumplimiento de entrega
    FechaEntregaPrometida DATE   NULL,
    FechaEntregaReal      DATE   NULL,
    ClienteId       INT           NOT NULL,
    CondicionPagoId INT           NULL,
    -- [BI] Empleado que generó el pedido (vendedor) para KPI de ventas por vendedor
    EmpleadoId      INT           NULL,
    Estado          VARCHAR(30)   NOT NULL DEFAULT 'BORRADOR',
    Observaciones   VARCHAR(500)  NULL,
    Subtotal        DECIMAL(18,2) NOT NULL DEFAULT 0,
    TotalImpuestos  DECIMAL(18,2) NOT NULL DEFAULT 0,
    Total           DECIMAL(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT UQ_PedidosVenta_Serie_Numero UNIQUE (Serie, Numero),
    CONSTRAINT FK_PedVenta_Cliente   FOREIGN KEY (ClienteId)       REFERENCES Clientes(Id),
    CONSTRAINT FK_PedVenta_Condicion FOREIGN KEY (CondicionPagoId) REFERENCES CondicionesPago(Id),
    CONSTRAINT FK_PedVenta_Empleado  FOREIGN KEY (EmpleadoId)      REFERENCES Empleados(Id)
);
CREATE INDEX IX_PedidosVenta_Fecha ON PedidosVenta(Fecha);
CREATE INDEX IX_PedidosVenta_Estado ON PedidosVenta(Estado);

CREATE TABLE PedidoVentaLineas (
    Id                 INT AUTO_INCREMENT PRIMARY KEY,
    PedidoVentaId      INT           NOT NULL,
    ProductoId         INT           NOT NULL,
    Cantidad           DECIMAL(18,4) NOT NULL,
    PrecioUnitario     DECIMAL(18,2) NOT NULL,
    ImpuestoPorcentaje DECIMAL(5,2)  NOT NULL DEFAULT 0,
    ImporteNeto        DECIMAL(18,2) NOT NULL DEFAULT 0,
    ImporteImpuesto    DECIMAL(18,2) NOT NULL DEFAULT 0,
    ImporteTotal       DECIMAL(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT FK_PedLinea_Pedido   FOREIGN KEY (PedidoVentaId) REFERENCES PedidosVenta(Id) ON DELETE CASCADE,
    CONSTRAINT FK_PedLinea_Producto FOREIGN KEY (ProductoId)    REFERENCES Productos(Id)
);

-- ============================================================
--  8. FACTURAS DE VENTA
-- ============================================================

CREATE TABLE FacturasVenta (
    Id               INT AUTO_INCREMENT PRIMARY KEY,
    Serie            VARCHAR(10)   NOT NULL,
    Numero           INT           NOT NULL,
    Fecha            DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FechaVencimiento DATE          NULL,
    ClienteId        INT           NOT NULL,
    PedidoVentaId    INT           NULL,
    CondicionPagoId  INT           NULL,
    -- [BI] Empleado vendedor para KPI de efectividad por vendedor
    EmpleadoId       INT           NULL,
    Estado           VARCHAR(30)   NOT NULL DEFAULT 'EMITIDA',
    Observaciones    VARCHAR(500)  NULL,
    Subtotal         DECIMAL(18,2) NOT NULL DEFAULT 0,
    TotalImpuestos   DECIMAL(18,2) NOT NULL DEFAULT 0,
    Total            DECIMAL(18,2) NOT NULL DEFAULT 0,
    -- [BI] Descuento global aplicado para análisis de márgenes
    Descuento        DECIMAL(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT UQ_FacturasVenta_Serie_Numero UNIQUE (Serie, Numero),
    CONSTRAINT FK_FactVenta_Cliente   FOREIGN KEY (ClienteId)       REFERENCES Clientes(Id),
    CONSTRAINT FK_FactVenta_Pedido    FOREIGN KEY (PedidoVentaId)   REFERENCES PedidosVenta(Id),
    CONSTRAINT FK_FactVenta_Condicion FOREIGN KEY (CondicionPagoId) REFERENCES CondicionesPago(Id),
    CONSTRAINT FK_FactVenta_Empleado  FOREIGN KEY (EmpleadoId)      REFERENCES Empleados(Id)
);
CREATE INDEX IX_FacturasVenta_Fecha    ON FacturasVenta(Fecha);
CREATE INDEX IX_FacturasVenta_Cliente  ON FacturasVenta(ClienteId, Fecha);
CREATE INDEX IX_FacturasVenta_Estado   ON FacturasVenta(Estado);

CREATE TABLE FacturaVentaLineas (
    Id                 INT AUTO_INCREMENT PRIMARY KEY,
    FacturaVentaId     INT           NOT NULL,
    ProductoId         INT           NOT NULL,
    Cantidad           DECIMAL(18,4) NOT NULL,
    PrecioUnitario     DECIMAL(18,2) NOT NULL,
    -- [BI] Costo al momento de la venta para calcular margen bruto por línea
    CostoUnitario      DECIMAL(18,2) NOT NULL DEFAULT 0,
    ImpuestoPorcentaje DECIMAL(5,2)  NOT NULL DEFAULT 0,
    ImporteNeto        DECIMAL(18,2) NOT NULL DEFAULT 0,
    ImporteImpuesto    DECIMAL(18,2) NOT NULL DEFAULT 0,
    ImporteTotal       DECIMAL(18,2) NOT NULL DEFAULT 0,
    -- [BI] Margen bruto calculado = ImporteNeto - (Cantidad * CostoUnitario)
    MargenBruto        DECIMAL(18,2) GENERATED ALWAYS AS (ImporteNeto - (Cantidad * CostoUnitario)) STORED,
    CONSTRAINT FK_FactLinea_Factura  FOREIGN KEY (FacturaVentaId) REFERENCES FacturasVenta(Id) ON DELETE CASCADE,
    CONSTRAINT FK_FactLinea_Producto FOREIGN KEY (ProductoId)     REFERENCES Productos(Id)
);

-- ============================================================
--  9. COBROS
-- ============================================================

CREATE TABLE Cobros (
    Id             INT AUTO_INCREMENT PRIMARY KEY,
    FacturaVentaId INT           NOT NULL,
    Fecha          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Monto          DECIMAL(18,2) NOT NULL,
    MedioPago      VARCHAR(50)   NULL,  -- 'EFECTIVO','TRANSFERENCIA','TARJETA','CHEQUE'
    Referencia     VARCHAR(100)  NULL,
    Observacion    VARCHAR(300)  NULL,
    -- [BI] Días transcurridos desde emisión hasta cobro (calculado en ETL)
    DiasParaCobro  INT           NULL,
    CONSTRAINT FK_Cobros_Factura FOREIGN KEY (FacturaVentaId) REFERENCES FacturasVenta(Id)
);
CREATE INDEX IX_Cobros_Fecha ON Cobros(Fecha);
CREATE INDEX IX_Cobros_MedioPago ON Cobros(MedioPago);

-- ============================================================
--  10. EMPLEADOS
-- ============================================================

CREATE TABLE Empleados (
    Id              INT AUTO_INCREMENT PRIMARY KEY,
    Nombres         VARCHAR(100) NOT NULL,
    Apellidos       VARCHAR(100) NOT NULL,
    Documento       VARCHAR(20)  NOT NULL,
    TipoDocumento   VARCHAR(20)  NOT NULL DEFAULT 'CC',
    Telefono        VARCHAR(30)  NULL,
    Email           VARCHAR(150) NULL,
    FechaNacimiento DATE         NULL,
    FechaIngreso    DATE         NOT NULL,
    -- [BI] Fecha de retiro para calcular rotación de personal
    FechaRetiro     DATE         NULL,
    DepartamentoId  INT          NULL,
    CargoId         INT          NULL,
    AlmacenId       INT          NULL,
    -- [BI] Género para reportes de equidad laboral
    Genero          VARCHAR(20)  NULL,
    Activo          TINYINT(1)   NOT NULL DEFAULT 1,
    CONSTRAINT UQ_Empleados_Documento UNIQUE (Documento),
    CONSTRAINT FK_Empleados_Departamento FOREIGN KEY (DepartamentoId) REFERENCES Departamentos(Id),
    CONSTRAINT FK_Empleados_Cargo        FOREIGN KEY (CargoId)        REFERENCES Cargos(Id),
    CONSTRAINT FK_Empleados_Almacen      FOREIGN KEY (AlmacenId)      REFERENCES Almacenes(Id)
);

-- ============================================================
--  11. CONTRATOS
-- ============================================================

CREATE TABLE Contratos (
    Id             INT AUTO_INCREMENT PRIMARY KEY,
    EmpleadoId     INT           NOT NULL,
    TipoContratoId INT           NOT NULL,
    FechaInicio    DATE          NOT NULL,
    FechaFin       DATE          NULL,
    Salario        DECIMAL(18,2) NOT NULL,
    Activo         TINYINT(1)    NOT NULL DEFAULT 1,
    CONSTRAINT FK_Contratos_Empleado     FOREIGN KEY (EmpleadoId)     REFERENCES Empleados(Id),
    CONSTRAINT FK_Contratos_TipoContrato FOREIGN KEY (TipoContratoId) REFERENCES TiposContrato(Id)
);

-- ============================================================
--  12. PERÍODOS DE NÓMINA
-- ============================================================

CREATE TABLE PeriodosNomina (
    Id          INT AUTO_INCREMENT PRIMARY KEY,
    Anio        INT         NOT NULL,
    Mes         INT         NOT NULL,
    FechaInicio DATE        NOT NULL,
    FechaFin    DATE        NOT NULL,
    Estado      VARCHAR(20) NOT NULL DEFAULT 'ABIERTO',
    CONSTRAINT UQ_PeriodosNomina_Anio_Mes UNIQUE (Anio, Mes)
);

-- ============================================================
--  13. NÓMINAS
-- ============================================================

CREATE TABLE Nominas (
    Id              INT AUTO_INCREMENT PRIMARY KEY,
    PeriodoNominaId INT           NOT NULL,
    EmpleadoId      INT           NOT NULL,
    ContratoId      INT           NULL,
    SalarioBase     DECIMAL(18,2) NOT NULL DEFAULT 0,
    AuxTransporte   DECIMAL(18,2) NOT NULL DEFAULT 0,
    TotalDevengado  DECIMAL(18,2) NOT NULL DEFAULT 0,
    TotalDeduccion  DECIMAL(18,2) NOT NULL DEFAULT 0,
    NetoPagar       DECIMAL(18,2) NOT NULL DEFAULT 0,
    Estado          VARCHAR(20)   NOT NULL DEFAULT 'CALCULADA',
    CONSTRAINT FK_Nominas_Periodo   FOREIGN KEY (PeriodoNominaId) REFERENCES PeriodosNomina(Id),
    CONSTRAINT FK_Nominas_Empleado  FOREIGN KEY (EmpleadoId)      REFERENCES Empleados(Id),
    CONSTRAINT FK_Nominas_Contrato  FOREIGN KEY (ContratoId)      REFERENCES Contratos(Id)
);

-- ============================================================
--  14. NOVEDADES DE NÓMINA
-- ============================================================

CREATE TABLE NovedadesNomina (
    Id              INT AUTO_INCREMENT PRIMARY KEY,
    PeriodoNominaId INT           NOT NULL,
    EmpleadoId      INT           NOT NULL,
    TipoNovedad     VARCHAR(50)   NOT NULL,
    Dias            DECIMAL(5,2)  NULL,
    Horas           DECIMAL(6,2)  NULL,
    Valor           DECIMAL(18,2) NULL,
    Observacion     VARCHAR(300)  NULL,
    CONSTRAINT FK_NovNomina_Periodo  FOREIGN KEY (PeriodoNominaId) REFERENCES PeriodosNomina(Id),
    CONSTRAINT FK_NovNomina_Empleado FOREIGN KEY (EmpleadoId)      REFERENCES Empleados(Id)
);

-- ============================================================
--  15. LIQUIDACIONES
-- ============================================================

CREATE TABLE Liquidaciones (
    Id               INT AUTO_INCREMENT PRIMARY KEY,
    EmpleadoId       INT           NOT NULL,
    ContratoId       INT           NULL,
    FechaLiquidacion DATE          NOT NULL DEFAULT (CURRENT_DATE),
    Cesantias        DECIMAL(18,2) NOT NULL DEFAULT 0,
    IntCesantias     DECIMAL(18,2) NOT NULL DEFAULT 0,
    Prima            DECIMAL(18,2) NOT NULL DEFAULT 0,
    Vacaciones       DECIMAL(18,2) NOT NULL DEFAULT 0,
    Indemnizacion    DECIMAL(18,2) NOT NULL DEFAULT 0,
    Total            DECIMAL(18,2) NOT NULL DEFAULT 0,
    Observacion      VARCHAR(500)  NULL,
    CONSTRAINT FK_Liquidaciones_Empleado FOREIGN KEY (EmpleadoId) REFERENCES Empleados(Id),
    CONSTRAINT FK_Liquidaciones_Contrato FOREIGN KEY (ContratoId) REFERENCES Contratos(Id)
);

-- ============================================================
--  16. NOTIFICACIONES
-- ============================================================

CREATE TABLE Notificaciones (
    Id         INT AUTO_INCREMENT PRIMARY KEY,
    Tipo       VARCHAR(50)  NOT NULL,
    Mensaje    VARCHAR(500) NOT NULL,
    ProductoId INT          NULL,
    AlmacenId  INT          NULL,
    Visto      TINYINT(1)   NOT NULL DEFAULT 0,
    Creado     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_Notif_Producto FOREIGN KEY (ProductoId) REFERENCES Productos(Id),
    CONSTRAINT FK_Notif_Almacen  FOREIGN KEY (AlmacenId)  REFERENCES Almacenes(Id)
);
CREATE INDEX IX_Notif_Tipo_Producto_Almacen_Visto_Creado
    ON Notificaciones(Tipo, ProductoId, AlmacenId, Visto, Creado);

-- ============================================================
--  17. [NUEVO] FACTURAS DE COMPRA (Cuentas por pagar)
--  Necesario para KPIs de ciclo de compra y rotación de proveedores
-- ============================================================

CREATE TABLE FacturasCompra (
    Id              INT AUTO_INCREMENT PRIMARY KEY,
    NumeroFactura   VARCHAR(50)   NOT NULL,
    Fecha           DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FechaVencimiento DATE         NULL,
    ProveedorId     INT           NOT NULL,
    CondicionPagoId INT           NULL,
    Estado          VARCHAR(30)   NOT NULL DEFAULT 'PENDIENTE',  -- 'PENDIENTE','PAGADA','ANULADA'
    Subtotal        DECIMAL(18,2) NOT NULL DEFAULT 0,
    TotalImpuestos  DECIMAL(18,2) NOT NULL DEFAULT 0,
    Total           DECIMAL(18,2) NOT NULL DEFAULT 0,
    Observaciones   VARCHAR(500)  NULL,
    CONSTRAINT FK_FactCompra_Proveedor  FOREIGN KEY (ProveedorId)     REFERENCES Proveedores(Id),
    CONSTRAINT FK_FactCompra_Condicion  FOREIGN KEY (CondicionPagoId) REFERENCES CondicionesPago(Id)
);
CREATE INDEX IX_FacturasCompra_Fecha      ON FacturasCompra(Fecha);
CREATE INDEX IX_FacturasCompra_Proveedor  ON FacturasCompra(ProveedorId, Fecha);
CREATE INDEX IX_FacturasCompra_Estado     ON FacturasCompra(Estado);

CREATE TABLE FacturaCompraLineas (
    Id               INT AUTO_INCREMENT PRIMARY KEY,
    FacturaCompraId  INT           NOT NULL,
    ProductoId       INT           NOT NULL,
    Cantidad         DECIMAL(18,4) NOT NULL,
    PrecioUnitario   DECIMAL(18,2) NOT NULL,
    ImpuestoPorcentaje DECIMAL(5,2) NOT NULL DEFAULT 0,
    ImporteNeto      DECIMAL(18,2) NOT NULL DEFAULT 0,
    ImporteImpuesto  DECIMAL(18,2) NOT NULL DEFAULT 0,
    ImporteTotal     DECIMAL(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT FK_FactCompLinea_Factura  FOREIGN KEY (FacturaCompraId) REFERENCES FacturasCompra(Id) ON DELETE CASCADE,
    CONSTRAINT FK_FactCompLinea_Producto FOREIGN KEY (ProductoId)      REFERENCES Productos(Id)
);

-- ============================================================
--  18. [NUEVO] PAGOS A PROVEEDORES
--  Para calcular DSO/DPO y análisis de liquidez
-- ============================================================

CREATE TABLE PagosProveedor (
    Id              INT AUTO_INCREMENT PRIMARY KEY,
    FacturaCompraId INT           NOT NULL,
    Fecha           DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Monto           DECIMAL(18,2) NOT NULL,
    MedioPago       VARCHAR(50)   NULL,
    Referencia      VARCHAR(100)  NULL,
    -- [BI] Días desde vencimiento hasta pago (positivo = pago tardío)
    DiasDesdeVencimiento INT      NULL,
    Observacion     VARCHAR(300)  NULL,
    CONSTRAINT FK_PagosProv_Factura FOREIGN KEY (FacturaCompraId) REFERENCES FacturasCompra(Id)
);
CREATE INDEX IX_PagosProv_Fecha ON PagosProveedor(Fecha);

-- ============================================================
--  19. [NUEVO] DEVOLUCIONES DE VENTA
--  Para calcular tasa de devoluciones (KPI de calidad)
-- ============================================================

CREATE TABLE DevolucionesVenta (
    Id               INT AUTO_INCREMENT PRIMARY KEY,
    FacturaVentaId   INT           NOT NULL,
    Fecha            DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Motivo           VARCHAR(100)  NOT NULL,  -- 'DEFECTO','ERROR_PEDIDO','INSATISFACCION','OTRO'
    Estado           VARCHAR(30)   NOT NULL DEFAULT 'PENDIENTE',
    Total            DECIMAL(18,2) NOT NULL DEFAULT 0,
    Observacion      VARCHAR(500)  NULL,
    CONSTRAINT FK_DevVenta_Factura FOREIGN KEY (FacturaVentaId) REFERENCES FacturasVenta(Id)
);

CREATE TABLE DevolucionVentaLineas (
    Id                  INT AUTO_INCREMENT PRIMARY KEY,
    DevolucionVentaId   INT           NOT NULL,
    ProductoId          INT           NOT NULL,
    Cantidad            DECIMAL(18,4) NOT NULL,
    PrecioUnitario      DECIMAL(18,2) NOT NULL,
    ImporteTotal        DECIMAL(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT FK_DevVentaLinea_Dev     FOREIGN KEY (DevolucionVentaId) REFERENCES DevolucionesVenta(Id) ON DELETE CASCADE,
    CONSTRAINT FK_DevVentaLinea_Prod    FOREIGN KEY (ProductoId)        REFERENCES Productos(Id)
);

-- ============================================================
--  20. [NUEVO] METAS DE VENTAS
--  Para KPI de cumplimiento de meta comercial
-- ============================================================

CREATE TABLE MetasVentas (
    Id           INT AUTO_INCREMENT PRIMARY KEY,
    Anio         INT           NOT NULL,
    Mes          INT           NOT NULL,
    EmpleadoId   INT           NULL,   -- NULL = meta global de la empresa
    CategoriaId  INT           NULL,   -- NULL = aplica a todo producto
    MontoMeta    DECIMAL(18,2) NOT NULL DEFAULT 0,
    CantidadMeta DECIMAL(18,4) NULL,
    Observacion  VARCHAR(300)  NULL,
    CONSTRAINT FK_MetasVentas_Empleado  FOREIGN KEY (EmpleadoId)  REFERENCES Empleados(Id),
    CONSTRAINT FK_MetasVentas_Categoria FOREIGN KEY (CategoriaId) REFERENCES Categorias(Id)
);
CREATE INDEX IX_MetasVentas_AnioMes ON MetasVentas(Anio, Mes);

-- ============================================================
--  21. [NUEVO] AUSENCIAS Y ASISTENCIA
--  Para KPI de ausentismo laboral
-- ============================================================

CREATE TABLE AusenciasEmpleado (
    Id           INT AUTO_INCREMENT PRIMARY KEY,
    EmpleadoId   INT          NOT NULL,
    FechaInicio  DATE         NOT NULL,
    FechaFin     DATE         NOT NULL,
    TipoAusencia VARCHAR(50)  NOT NULL,  -- 'INCAPACIDAD','VACACIONES','PERMISO','FALTA'
    DiasAusencia INT          GENERATED ALWAYS AS (DATEDIFF(FechaFin, FechaInicio) + 1) STORED,
    Justificada  TINYINT(1)   NOT NULL DEFAULT 1,
    Observacion  VARCHAR(300) NULL,
    CONSTRAINT FK_Ausencias_Empleado FOREIGN KEY (EmpleadoId) REFERENCES Empleados(Id)
);
CREATE INDEX IX_Ausencias_EmpleadoFecha ON AusenciasEmpleado(EmpleadoId, FechaInicio);
CREATE INDEX IX_Ausencias_Tipo ON AusenciasEmpleado(TipoAusencia, FechaInicio);

-- ============================================================
--  22. [NUEVO] LOG ETL – CONTROL DE CARGAS AL DW
--  Para auditoría y trazabilidad de procesos ETL
-- ============================================================

CREATE TABLE ETL_LogCarga (
    Id              INT AUTO_INCREMENT PRIMARY KEY,
    NombreProceso   VARCHAR(100) NOT NULL,
    FechaInicio     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FechaFin        DATETIME     NULL,
    Estado          VARCHAR(20)  NOT NULL DEFAULT 'EJECUTANDO',  -- 'EJECUTANDO','OK','ERROR'
    RegistrosProcesados INT      NULL,
    RegistrosInsertados INT      NULL,
    RegistrosActualizados INT    NULL,
    RegistrosRechazados INT      NULL,
    MensajeError    TEXT         NULL,
    UsuarioEjecucion VARCHAR(100) NULL
);
CREATE INDEX IX_ETL_Log_Proceso_Fecha ON ETL_LogCarga(NombreProceso, FechaInicio);

-- ============================================================
--  23. [NUEVO] DIMENSIÓN TIEMPO (tabla auxiliar para DW)
--  Pre-generada para joins eficientes en consultas BI
-- ============================================================

CREATE TABLE DimTiempo (
    FechaKey       INT     PRIMARY KEY,  -- YYYYMMDD
    Fecha          DATE    NOT NULL,
    Anio           SMALLINT NOT NULL,
    Trimestre      TINYINT  NOT NULL,
    Mes            TINYINT  NOT NULL,
    NombreMes      VARCHAR(20) NOT NULL,
    Semana         TINYINT  NOT NULL,
    DiaSemana      TINYINT  NOT NULL,
    NombreDia      VARCHAR(20) NOT NULL,
    EsFinDeSemana  TINYINT(1) NOT NULL DEFAULT 0,
    EsFestivo      TINYINT(1) NOT NULL DEFAULT 0,
    NombreFestivo  VARCHAR(100) NULL
);
CREATE INDEX IX_DimTiempo_Fecha  ON DimTiempo(Fecha);
CREATE INDEX IX_DimTiempo_AnioMes ON DimTiempo(Anio, Mes);

-- Procedimiento para poblar DimTiempo (rango configurable)
DELIMITER //
CREATE PROCEDURE sp_PoblarDimTiempo(
    IN p_FechaInicio DATE,
    IN p_FechaFin    DATE
)
BEGIN
    DECLARE v_Fecha DATE DEFAULT p_FechaInicio;
    WHILE v_Fecha <= p_FechaFin DO
        INSERT IGNORE INTO DimTiempo (
            FechaKey, Fecha, Anio, Trimestre, Mes, NombreMes,
            Semana, DiaSemana, NombreDia, EsFinDeSemana
        ) VALUES (
            DATE_FORMAT(v_Fecha, '%Y%m%d') + 0,
            v_Fecha,
            YEAR(v_Fecha),
            QUARTER(v_Fecha),
            MONTH(v_Fecha),
            DATE_FORMAT(v_Fecha, '%M'),
            WEEK(v_Fecha, 1),
            DAYOFWEEK(v_Fecha),
            DATE_FORMAT(v_Fecha, '%W'),
            IF(DAYOFWEEK(v_Fecha) IN (1,7), 1, 0)
        );
        SET v_Fecha = DATE_ADD(v_Fecha, INTERVAL 1 DAY);
    END WHILE;
END //
DELIMITER ;

-- Poblar dimensión tiempo 2023–2027
CALL sp_PoblarDimTiempo('2023-01-01', '2027-12-31');

-- ============================================================
--  VISTAS PARA KPIs
--  Sirven como capa semántica lista para conectar a herramientas
--  BI (Power BI, Tableau, Metabase, etc.)
-- ============================================================

-- --------------------------------------------------------
--  KPI 1: Ventas brutas por período, cliente y vendedor
-- --------------------------------------------------------
CREATE OR REPLACE VIEW vw_KPI_VentasBrutas AS
SELECT
    DATE_FORMAT(fv.Fecha, '%Y-%m') AS Periodo,
    YEAR(fv.Fecha)                 AS Anio,
    MONTH(fv.Fecha)                AS Mes,
    c.Id                           AS ClienteId,
    c.RazonSocial                  AS Cliente,
    c.Segmento                     AS SegmentoCliente,
    c.Ciudad                       AS CiudadCliente,
    e.Id                           AS VendedorId,
    CONCAT(e.Nombres,' ',e.Apellidos) AS Vendedor,
    COUNT(DISTINCT fv.Id)          AS NumFacturas,
    SUM(fv.Subtotal)               AS VentasNetas,
    SUM(fv.TotalImpuestos)         AS TotalImpuestos,
    SUM(fv.Total)                  AS VentasBrutas,
    SUM(fv.Descuento)              AS TotalDescuentos
FROM FacturasVenta fv
INNER JOIN Clientes  c ON c.Id = fv.ClienteId
LEFT  JOIN Empleados e ON e.Id = fv.EmpleadoId
WHERE fv.Estado NOT IN ('ANULADA')
GROUP BY 1,2,3,4,5,6,7,8,9;

-- --------------------------------------------------------
--  KPI 2: Margen bruto por producto y categoría
-- --------------------------------------------------------
CREATE OR REPLACE VIEW vw_KPI_MargenBruto AS
SELECT
    DATE_FORMAT(fv.Fecha, '%Y-%m') AS Periodo,
    p.Id                           AS ProductoId,
    p.NombreProducto               AS Producto,
    p.Sku,
    cat.Nombre                     AS Categoria,
    m.Nombre                       AS Marca,
    SUM(fl.Cantidad)               AS UnidadesVendidas,
    SUM(fl.ImporteNeto)            AS IngresoNeto,
    SUM(fl.Cantidad * fl.CostoUnitario) AS CostoVentas,
    SUM(fl.MargenBruto)            AS MargenBruto,
    ROUND(
        SUM(fl.MargenBruto) / NULLIF(SUM(fl.ImporteNeto),0) * 100
    , 2)                           AS PorcentajeMargen
FROM FacturaVentaLineas fl
INNER JOIN FacturasVenta fv  ON fv.Id  = fl.FacturaVentaId
INNER JOIN Productos     p   ON p.Id   = fl.ProductoId
INNER JOIN Categorias    cat ON cat.Id = p.CategoriaId
LEFT  JOIN Marcas        m   ON m.Id   = p.MarcaId
WHERE fv.Estado NOT IN ('ANULADA')
GROUP BY 1,2,3,4,5,6;

-- --------------------------------------------------------
--  KPI 3: Rotación de inventario por producto y almacén
-- --------------------------------------------------------
CREATE OR REPLACE VIEW vw_KPI_RotacionInventario AS
SELECT
    p.Id              AS ProductoId,
    p.NombreProducto  AS Producto,
    a.Nombre          AS Almacen,
    e.Cantidad        AS StockActual,
    p.StockMinimo,
    p.CostoPromedio,
    e.Cantidad * p.CostoPromedio  AS ValorInventario,
    -- Unidades vendidas en los últimos 12 meses
    COALESCE(v.UnidadesVendidas12M, 0) AS UnidadesVendidas12M,
    -- Rotación = Costo ventas / Inventario promedio (aprox con stock actual)
    ROUND(
        COALESCE(v.UnidadesVendidas12M, 0) / NULLIF(e.Cantidad, 0)
    , 2)              AS IndicadorRotacion,
    -- Días en inventario
    ROUND(
        365 / NULLIF(
            COALESCE(v.UnidadesVendidas12M, 0) / NULLIF(e.Cantidad, 0)
        , 0)
    , 0)              AS DiasInventario,
    CASE
        WHEN e.Cantidad <= 0           THEN 'AGOTADO'
        WHEN e.Cantidad < p.StockMinimo THEN 'BAJO_MINIMO'
        WHEN e.Cantidad > p.StockMaximo AND p.StockMaximo > 0 THEN 'SOBRE_STOCK'
        ELSE 'NORMAL'
    END               AS EstadoStock
FROM Existencias e
INNER JOIN Productos p ON p.Id = e.ProductoId
INNER JOIN Almacenes a ON a.Id = e.AlmacenId
LEFT JOIN (
    SELECT fl.ProductoId, SUM(fl.Cantidad) AS UnidadesVendidas12M
    FROM FacturaVentaLineas fl
    INNER JOIN FacturasVenta fv ON fv.Id = fl.FacturaVentaId
    WHERE fv.Fecha >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
      AND fv.Estado NOT IN ('ANULADA')
    GROUP BY fl.ProductoId
) v ON v.ProductoId = e.ProductoId;

-- --------------------------------------------------------
--  KPI 4: Cartera vencida y DSO (Days Sales Outstanding)
-- --------------------------------------------------------
CREATE OR REPLACE VIEW vw_KPI_CarteraVencida AS
SELECT
    c.Id                         AS ClienteId,
    c.RazonSocial                AS Cliente,
    c.Segmento,
    fv.Id                        AS FacturaId,
    fv.Serie, fv.Numero,
    fv.Fecha                     AS FechaEmision,
    fv.FechaVencimiento,
    fv.Total                     AS MontoFactura,
    COALESCE(SUM(co.Monto),0)    AS MontoCobrado,
    fv.Total - COALESCE(SUM(co.Monto),0) AS SaldoPendiente,
    DATEDIFF(CURDATE(), fv.FechaVencimiento) AS DiasVencida,
    CASE
        WHEN fv.FechaVencimiento IS NULL THEN 'SIN_VENCIMIENTO'
        WHEN DATEDIFF(CURDATE(), fv.FechaVencimiento) <= 0  THEN 'VIGENTE'
        WHEN DATEDIFF(CURDATE(), fv.FechaVencimiento) <= 30 THEN 'VENCIDA_0_30'
        WHEN DATEDIFF(CURDATE(), fv.FechaVencimiento) <= 60 THEN 'VENCIDA_31_60'
        WHEN DATEDIFF(CURDATE(), fv.FechaVencimiento) <= 90 THEN 'VENCIDA_61_90'
        ELSE 'VENCIDA_MAS_90'
    END                          AS BucketVencimiento
FROM FacturasVenta fv
INNER JOIN Clientes c ON c.Id = fv.ClienteId
LEFT  JOIN Cobros co ON co.FacturaVentaId = fv.Id
WHERE fv.Estado NOT IN ('ANULADA')
GROUP BY c.Id, c.RazonSocial, c.Segmento,
         fv.Id, fv.Serie, fv.Numero, fv.Fecha, fv.FechaVencimiento, fv.Total
HAVING SaldoPendiente > 0.01;

-- --------------------------------------------------------
--  KPI 5: Costo de nómina por departamento y período
-- --------------------------------------------------------
CREATE OR REPLACE VIEW vw_KPI_CostoNomina AS
SELECT
    pn.Anio,
    pn.Mes,
    d.Nombre                    AS Departamento,
    d.CentroCosto,
    COUNT(DISTINCT n.EmpleadoId) AS NumEmpleados,
    SUM(n.SalarioBase)           AS TotalSalarios,
    SUM(n.AuxTransporte)         AS TotalAuxTransporte,
    SUM(n.TotalDevengado)        AS TotalDevengado,
    SUM(n.TotalDeduccion)        AS TotalDeducciones,
    SUM(n.NetoPagar)             AS TotalNetoPagar
FROM Nominas n
INNER JOIN PeriodosNomina pn ON pn.Id = n.PeriodoNominaId
INNER JOIN Empleados      em ON em.Id = n.EmpleadoId
LEFT  JOIN Departamentos  d  ON d.Id  = em.DepartamentoId
WHERE n.Estado = 'PAGADA'
GROUP BY pn.Anio, pn.Mes, d.Nombre, d.CentroCosto;

-- --------------------------------------------------------
--  KPI 6: Cumplimiento de metas de ventas
-- --------------------------------------------------------
CREATE OR REPLACE VIEW vw_KPI_CumplimientoMetas AS
SELECT
    mv.Anio,
    mv.Mes,
    e.Id                              AS VendedorId,
    CONCAT(e.Nombres,' ',e.Apellidos) AS Vendedor,
    mv.MontoMeta,
    COALESCE(SUM(fv.Total), 0)        AS VentasReales,
    ROUND(
        COALESCE(SUM(fv.Total), 0) / NULLIF(mv.MontoMeta, 0) * 100
    , 2)                              AS PorcentajeCumplimiento
FROM MetasVentas mv
LEFT JOIN Empleados    e  ON e.Id = mv.EmpleadoId
LEFT JOIN FacturasVenta fv ON fv.EmpleadoId = mv.EmpleadoId
    AND YEAR(fv.Fecha)  = mv.Anio
    AND MONTH(fv.Fecha) = mv.Mes
    AND fv.Estado NOT IN ('ANULADA')
WHERE mv.EmpleadoId IS NOT NULL
GROUP BY mv.Anio, mv.Mes, e.Id, e.Nombres, e.Apellidos, mv.MontoMeta;

-- --------------------------------------------------------
--  KPI 7: Tasa de devoluciones por producto y motivo
-- --------------------------------------------------------
CREATE OR REPLACE VIEW vw_KPI_Devoluciones AS
SELECT
    DATE_FORMAT(fv.Fecha, '%Y-%m')   AS Periodo,
    p.Id                             AS ProductoId,
    p.NombreProducto                 AS Producto,
    cat.Nombre                       AS Categoria,
    dv.Motivo,
    COUNT(DISTINCT dv.Id)            AS NumDevoluciones,
    SUM(dvl.Cantidad)                AS UnidadesDevueltas,
    SUM(dvl.ImporteTotal)            AS MontoDevuelto,
    -- Porcentaje vs ventas del período
    ROUND(
        SUM(dvl.ImporteTotal) /
        NULLIF((
            SELECT SUM(fl2.ImporteNeto)
            FROM FacturaVentaLineas fl2
            INNER JOIN FacturasVenta fv2 ON fv2.Id = fl2.FacturaVentaId
            WHERE fl2.ProductoId = p.Id
              AND DATE_FORMAT(fv2.Fecha,'%Y-%m') = DATE_FORMAT(fv.Fecha,'%Y-%m')
              AND fv2.Estado NOT IN ('ANULADA')
        ), 0) * 100
    , 2)                             AS PorcentajeDevolucion
FROM DevolucionesVenta dv
INNER JOIN DevolucionVentaLineas dvl ON dvl.DevolucionVentaId = dv.Id
INNER JOIN FacturasVenta         fv  ON fv.Id = dv.FacturaVentaId
INNER JOIN Productos             p   ON p.Id  = dvl.ProductoId
INNER JOIN Categorias            cat ON cat.Id = p.CategoriaId
GROUP BY 1,2,3,4,5;

-- --------------------------------------------------------
--  KPI 8: Ausentismo laboral por departamento
-- --------------------------------------------------------
CREATE OR REPLACE VIEW vw_KPI_Ausentismo AS
SELECT
    YEAR(au.FechaInicio)             AS Anio,
    MONTH(au.FechaInicio)            AS Mes,
    d.Nombre                         AS Departamento,
    au.TipoAusencia,
    COUNT(DISTINCT au.EmpleadoId)    AS EmpleadosConAusencia,
    SUM(au.DiasAusencia)             AS TotalDiasAusencia,
    -- Tasa de ausentismo = días ausentes / (empleados activos * días hábiles del mes)
    -- Se calcula en el BI con el dato de empleados activos del período
    ROUND(AVG(au.DiasAusencia), 2)   AS PromedioDiasPorEmpleado
FROM AusenciasEmpleado au
INNER JOIN Empleados    em ON em.Id = au.EmpleadoId
LEFT  JOIN Departamentos d  ON d.Id  = em.DepartamentoId
GROUP BY 1,2,3,4;

-- --------------------------------------------------------
--  KPI 9: Antigüedad de proveedores y concentración de compras
-- --------------------------------------------------------
CREATE OR REPLACE VIEW vw_KPI_AnalisisProveedores AS
SELECT
    pr.Id                             AS ProveedorId,
    pr.RazonSocial                    AS Proveedor,
    pr.Clasificacion,
    pr.Ciudad,
    pr.Pais,
    TIMESTAMPDIFF(MONTH, pr.FechaVinculacion, CURDATE()) AS MesesVinculado,
    COUNT(DISTINCT fc.Id)             AS NumFacturasCompra,
    SUM(fc.Total)                     AS TotalCompras,
    ROUND(
        SUM(fc.Total) /
        NULLIF((SELECT SUM(Total) FROM FacturasCompra WHERE Estado != 'ANULADA'), 0) * 100
    , 2)                              AS PorcentajeConcentracion,
    -- DPO promedio en días
    AVG(pp.DiasDesdeVencimiento)      AS DPO_Promedio
FROM Proveedores pr
LEFT JOIN FacturasCompra fc ON fc.ProveedorId = pr.Id AND fc.Estado != 'ANULADA'
LEFT JOIN PagosProveedor pp ON pp.FacturaCompraId = fc.Id
WHERE pr.Activo = 1
GROUP BY pr.Id, pr.RazonSocial, pr.Clasificacion, pr.Ciudad, pr.Pais, pr.FechaVinculacion;

-- --------------------------------------------------------
--  KPI 10: Tiempo de ciclo de ventas (Pedido → Factura → Cobro)
-- --------------------------------------------------------
CREATE OR REPLACE VIEW vw_KPI_CicloVentas AS
SELECT
    fv.Id                               AS FacturaId,
    c.RazonSocial                        AS Cliente,
    c.Segmento,
    pv.Fecha                             AS FechaPedido,
    fv.Fecha                             AS FechaFactura,
    MIN(co.Fecha)                        AS FechaPrimerCobro,
    DATEDIFF(fv.Fecha, pv.Fecha)         AS DiasFacturacion,   -- Pedido → Factura
    DATEDIFF(MIN(co.Fecha), fv.Fecha)    AS DiasCobro,         -- Factura → Cobro
    DATEDIFF(MIN(co.Fecha), pv.Fecha)    AS DiasCicloTotal,    -- Pedido → Cobro
    fv.Total,
    CASE
        WHEN DATEDIFF(MIN(co.Fecha), fv.Fecha) <= 
             cp.DiasCredito THEN 'A_TIEMPO'
        ELSE 'TARDIO'
    END                                  AS EstadoCobro
FROM FacturasVenta fv
INNER JOIN Clientes        c  ON c.Id  = fv.ClienteId
LEFT  JOIN PedidosVenta    pv ON pv.Id = fv.PedidoVentaId
LEFT  JOIN Cobros          co ON co.FacturaVentaId = fv.Id
LEFT  JOIN CondicionesPago cp ON cp.Id = fv.CondicionPagoId
WHERE fv.Estado NOT IN ('ANULADA')
GROUP BY fv.Id, c.RazonSocial, c.Segmento,
         pv.Fecha, fv.Fecha, fv.Total, cp.DiasCredito;

-- ============================================================
--  PROCEDIMIENTOS ETL AUXILIARES
-- ============================================================

-- Actualiza DiasParaCobro en Cobros al momento del registro
DELIMITER //
CREATE PROCEDURE sp_ETL_ActualizarDiasCobro()
BEGIN
    UPDATE Cobros co
    INNER JOIN FacturasVenta fv ON fv.Id = co.FacturaVentaId
    SET co.DiasParaCobro = DATEDIFF(co.Fecha, fv.Fecha)
    WHERE co.DiasParaCobro IS NULL;
END //

-- Actualiza DiasDesdeVencimiento en PagosProveedor
CREATE PROCEDURE sp_ETL_ActualizarDPO()
BEGIN
    UPDATE PagosProveedor pp
    INNER JOIN FacturasCompra fc ON fc.Id = pp.FacturaCompraId
    SET pp.DiasDesdeVencimiento = DATEDIFF(pp.Fecha, fc.FechaVencimiento)
    WHERE pp.DiasDesdeVencimiento IS NULL
      AND fc.FechaVencimiento IS NOT NULL;
END //

-- Actualiza FechaUltimoMovimiento en Productos
CREATE PROCEDURE sp_ETL_ActualizarUltimoMovimiento()
BEGIN
    UPDATE Productos p
    INNER JOIN (
        SELECT ProductoId, MAX(Fecha) AS UltimaFecha
        FROM MovimientosInventario
        GROUP BY ProductoId
    ) ult ON ult.ProductoId = p.Id
    SET p.FechaUltimoMovimiento = ult.UltimaFecha;
END //

DELIMITER ;

-- ============================================================
--  FIN DEL SCRIPT
-- ============================================================
