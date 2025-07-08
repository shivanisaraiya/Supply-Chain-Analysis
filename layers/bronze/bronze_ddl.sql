-- bronze layer ddl
-- drop and create table bronze.supplier
DROP TABLE IF EXISTS bronze.suppliers;

CREATE TABLE bronze.suppliers (
	SupplierID VARCHAR(50),
	SupplierName VARCHAR(50),
	Country VARCHAR(50),
	Region VARCHAR(50),
	ContactEmail VARCHAR(50),
	Phone VARCHAR(50),
	YearsInBusiness VARCHAR,
	SupplierRating VARCHAR(50)
);

-- drop and create table bronze.product
DROP TABLE IF EXISTS bronze.products;

CREATE TABLE bronze.products (
	ProductID VARCHAR(50),
	ProductName VARCHAR(50),
	Category VARCHAR(50),
	SupplierID VARCHAR(50),
	UnitPrice REAL,
	StockQuantity REAL,
	ProductStatus VARCHAR(50),
	LaunchDate VARCHAR(50),
	Weight_kg REAL
);

-- drop and create table bronze.customers
DROP TABLE IF EXISTS bronze.customers;

CREATE TABLE bronze.customers (
	CustomerID VARCHAR(50),
	FirstName VARCHAR(50),
	LastName VARCHAR(50),
	Email VARCHAR(50),
	Address VARCHAR(50),
	City VARCHAR(50),
	PostalCode VARCHAR(50),
	RegistrationDate VARCHAR(50),
	LastLoginDate VARCHAR(50),
	CustomerSegment VARCHAR(50),
	DateOfBirth VARCHAR(50) DEFAULT NULL, -- to avoid missing column data
	Phone VARCHAR(50)
);

-- drop and create table bronze.orders
DROP TABLE IF EXISTS bronze.orders;

CREATE TABLE bronze.orders (
	OrderID VARCHAR(50),
	CustomerID VARCHAR(50),
	OrderDate VARCHAR(50),
	ShipDate VARCHAR(50),
	ExpectedDeliveryDate VARCHAR(50),
	ActualDeliveryDate VARCHAR(50),
	OrderStatus VARCHAR(50),
	ShippingMethod VARCHAR(50),
	ShippingCost_NGN REAL,
	ShippingAddress VARCHAR(50),
	ShippingCity VARCHAR(50),
	ShippingState VARCHAR(50),
	ShippingPostalCode VARCHAR(50),
	ShippingCountry VARCHAR(50),
	PaymentMethod VARCHAR(50),
	PaymentStatus VARCHAR(50),
	DiscountCode VARCHAR(50),
	DiscountAmount_NGN REAL,
	TotalAmount_NGN REAL
);

-- drop and create table bronze.order_item
DROP TABLE IF EXISTS bronze.order_items;

CREATE TABLE bronze.order_items (
	OrderItemID VARCHAR(50),
	OrderID VARCHAR(50),
	ProductID VARCHAR(50),
	Quantity INTEGER,
	UnitPriceAtPurchase_NGN REAL,
	TotalItemPrice_NGN REAL,
	ReturnStatus VARCHAR(50)
);