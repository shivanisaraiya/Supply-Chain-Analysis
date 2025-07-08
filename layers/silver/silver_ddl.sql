-- silver layer ddl
-- drop and create table silver.supplier
DROP TABLE IF EXISTS silver.suppliers;

CREATE TABLE silver.suppliers (
	SupplierID VARCHAR(50),
	SupplierName VARCHAR(50),
	Country VARCHAR(50),
	Region VARCHAR(50),
	ContactEmail VARCHAR(50),
	Phone VARCHAR(50),
	YearsInBusiness INTEGER,
	SupplierRating NUMERIC,
	ingestion_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- drop and create table silver.product
DROP TABLE IF EXISTS silver.products;

CREATE TABLE silver.products (
	ProductID VARCHAR(50),
	ProductName VARCHAR(50),
	Category VARCHAR(50),
	SupplierID VARCHAR(50),
	UnitPrice NUMERIC,
	StockQuantity INTEGER,
	ProductStatus VARCHAR(50),
	Stockhealth VARCHAR(50),
	StockAnomalyFlag VARCHAR(50),
	LaunchDate VARCHAR(50),
	Weight_kg NUMERIC,
	ingestion_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- drop and create table silver.customers
DROP TABLE IF EXISTS silver.customers;

CREATE TABLE silver.customers (
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
	DateOfBirth VARCHAR(50),
	Phone VARCHAR(50),
	Phone_Extension VARCHAR(50),
	ingestion_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- drop and create table silver.orders
DROP TABLE IF EXISTS silver.orders;

CREATE TABLE silver.orders (
	OrderID VARCHAR(50),
	CustomerID VARCHAR(50),
	OrderDate VARCHAR(50),
	ShipDate VARCHAR(50),
	ExpectedDeliveryDate VARCHAR(50),
	ActualDeliveryDate VARCHAR(50),
	OrderStatus VARCHAR(50),
	ShippingMethod VARCHAR(50),
	ShippingCost_NGN NUMERIC,
	ShippingAddress VARCHAR(50),
	ShippingCity VARCHAR(50),
	ShippingState VARCHAR(50),
	ShippingPostalCode VARCHAR(50),
	ShippingCountry VARCHAR(50),
	PaymentMethod VARCHAR(50),
	PaymentStatus VARCHAR(50),
	DiscountCode VARCHAR(50),
	DiscountAmount_NGN NUMERIC,
	TotalAmount_NGN NUMERIC,
	ingestion_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- drop and create table silver.order_item
DROP TABLE IF EXISTS silver.order_items;

CREATE TABLE silver.order_items (
	OrderItemID VARCHAR(50),
	OrderID VARCHAR(50),
	ProductID VARCHAR(50),
	Quantity INTEGER,
	UnitPriceAtPurchase_NGN NUMERIC,
	TotalItemPrice_NGN NUMERIC,
	ReturnStatus VARCHAR(50),
	ingestion_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);