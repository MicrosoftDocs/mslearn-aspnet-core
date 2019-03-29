-- Purge data from all tables
TRUNCATE TABLE dbo.ProductOrders
TRUNCATE TABLE dbo.Orders
TRUNCATE TABLE dbo.Products
TRUNCATE TABLE dbo.Customers

-- Populate Products table
INSERT INTO dbo.Products ([Name], Price) 
VALUES ('Knotted Rope', 14.99)

DECLARE @KnottedRopeProductId int = SCOPE_IDENTITY()

INSERT INTO dbo.Products ([Name], Price)
VALUES ('Squeaky Bone', 20.99)

DECLARE @SqueakyBoneProductId int = SCOPE_IDENTITY()

INSERT INTO dbo.Products ([Name], Price)
VALUES ('Plush Squirrel', 12.99)

DECLARE @PlushSquirrelProductId int = SCOPE_IDENTITY()

-- Populate Customers table
INSERT INTO dbo.Customers (FirstName, LastName, StreetAddress, City, StateOrProvinceAbbr, Country, PostalCode, Phone, Email)
VALUES ('Patrick', 'Hunt', '1 Microsoft Way', 'Redmond', 'WA', 'United States', '98052', '1-425-882-8080', 'patrick.hunt@microsoft.com')

DECLARE @PatrickHuntCustomerId int = SCOPE_IDENTITY()

INSERT INTO dbo.Customers (FirstName, LastName, StreetAddress, City, StateOrProvinceAbbr, Country, PostalCode, Phone, Email)
VALUES ('Elsa', 'York', '1 Microsoft Way', 'Redmond', 'WA', 'United States', '98052', '1-425-882-8080', 'elsa.york@microsoft.com')

DECLARE @ElsaYorkCustomerId int = SCOPE_IDENTITY()

-- Populate Orders table
INSERT INTO dbo.Orders (OrderPlaced, OrderFulfilled, CustomerId)
VALUES (DATEADD(DAY, -5, GETDATE()), NULL, @PatrickHuntCustomerId)

DECLARE @PatrickHuntOrderId1 int = SCOPE_IDENTITY()

INSERT INTO dbo.Orders (OrderPlaced, OrderFulfilled, CustomerId)
VALUES (DATEADD(DAY, -2, GETDATE()), NULL, @PatrickHuntCustomerId)

DECLARE @PatrickHuntOrderId2 int = SCOPE_IDENTITY()

-- Populate ProductOrders table
INSERT INTO dbo.ProductOrders (Quantity, ProductId, OrderId)
VALUES (3, @PlushSquirrelProductId, @PatrickHuntOrderId1)

INSERT INTO dbo.ProductOrders (Quantity, ProductId, OrderId)
VALUES (15, @SqueakyBoneProductId, @PatrickHuntOrderId1)

INSERT INTO dbo.ProductOrders (Quantity, ProductId, OrderId)
VALUES (6, @KnottedRopeProductId, @PatrickHuntOrderId2)
