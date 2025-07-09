
CREATE TABLE customers (
    CustomerId VARCHAR(50) PRIMARY KEY,
    City VARCHAR(50),
    RegistrationDate DATETIME , 
    LastLoginDate DATETIME, -- has blank values
    CustomerSegment VARCHAR(50)
);

CREATE TABLE orders (
    OrderID VARCHAR(20) PRIMARY KEY,
    CustomerID VARCHAR(20) NOT NULL,
    OrderDate DATETIME,             -- Has blanks
    ShipDate DATETIME,              -- Has blanks
    ExpectedDeliveryDate DATETIME,  -- Has blanks
    ActualDeliveryDate DATETIME,    -- Has blanks
    OrderStatus VARCHAR(50) NOT NULL,
    ShippingMethod VARCHAR(50) NOT NULL,
    ShippingCost_NGN DECIMAL(15, 4), -- Can be NULL
    ShippingCity VARCHAR(50) NOT NULL,
    PaymentStatus VARCHAR(50),      -- Can be NULL
    TotalAmount_NGN DECIMAL(15, 4) NOT NULL,
    ShippingType VARCHAR(50)        -- Can be NULL
);

ALTER TABLE orders
ADD CONSTRAINT fk_orders_customer
FOREIGN KEY (CustomerID)
REFERENCES customers (CustomerID);

CREATE TABLE supplier (
    SupplierID VARCHAR(20) PRIMARY KEY,
    SupplierName VARCHAR(100) NOT NULL,
    SupplierRating INT      -- Can be NULL
);

CREATE TABLE products (
    ProductId VARCHAR(20) PRIMARY KEY,
    ProductName VARCHAR(255) NOT NULL,
    Category VARCHAR(100) NOT NULL,
    SupplierId VARCHAR(20) NOT NULL,
    UnitPrice_NGN DECIMAL(15, 4) NOT NULL,
    StockQuantity INT,
    ProductStatus VARCHAR(50), -- can have blank values
    LaunchDate DATETIME NOT NULL, -- date format needs to be changed
    Weight_Kg DECIMAL(10, 2), -- can have blank values
    -- Adding the FOREIGN KEY constraint for SupplierId
    FOREIGN KEY (SupplierId) REFERENCES supplier(SupplierID)
);


CREATE TABLE order_items (
    OrderItemID VARCHAR(20) PRIMARY KEY,
    OrderID VARCHAR(20) NOT NULL,
    ProductID VARCHAR(20) NOT NULL,
    Quantity INT NOT NULL,
    UnitPriceAtPurchase_NGN DECIMAL(10, 2) NOT NULL,
    TotalItemPrice_NGN DECIMAL(10, 2), -- Can be NULL
    ReturnStatus VARCHAR(50), -- Can be NULL
    -- Adding foreign key constraints (assuming 'orders' and 'products' tables exist)
    FOREIGN KEY (OrderID) REFERENCES orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES products(ProductId)
);





-- Loading the Customers table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Supply Chain Project/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS 
(CustomerId, City, @RegistrationDateVar, @LastLoginDateVar, CustomerSegment)
SET
    RegistrationDate = STR_TO_DATE(@RegistrationDateVar, '%c/%e/%Y %H:%i'),
    LastLoginDate = STR_TO_DATE(NULLIF(@LastLoginDateVar, ''), '%c/%e/%Y %H:%i');

    
-- Loading the Orders table     
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Supply Chain Project/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(OrderID, CustomerID, @OrderDateVar, @ShipDateVar, @ExpectedDeliveryDateVar, @ActualDeliveryDateVar,
 OrderStatus, ShippingMethod, @ShippingCost_NGNVar, ShippingCity, @PaymentStatusVar, TotalAmount_NGN, @ShippingTypeVar)
SET
    OrderDate = STR_TO_DATE(NULLIF(@OrderDateVar, ''), '%m/%d/%Y %H:%i'),
    ShipDate = STR_TO_DATE(NULLIF(@ShipDateVar, ''), '%m/%d/%Y %H:%i'),
    ExpectedDeliveryDate = STR_TO_DATE(NULLIF(@ExpectedDeliveryDateVar, ''), '%m/%d/%Y'),
    ActualDeliveryDate = STR_TO_DATE(NULLIF(@ActualDeliveryDateVar, ''), '%m/%d/%Y %H:%i'),
    ShippingCost_NGN = IF(@ShippingCost_NGNVar = '', NULL, @ShippingCost_NGNVar),
    PaymentStatus = NULLIF(@PaymentStatusVar, ''),
    ShippingType = NULLIF(@ShippingTypeVar, '');
    

   -- Loading the Supplier table 
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Supply Chain Project/supplier.csv'
INTO TABLE supplier
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(SupplierID, SupplierName, @SupplierRatingVar)
SET
    SupplierRating = CASE
        WHEN TRIM(@SupplierRatingVar) = '' THEN NULL
        WHEN TRIM(@SupplierRatingVar) REGEXP '^[0-9]+$' THEN CONVERT(TRIM(@SupplierRatingVar), SIGNED INTEGER)
        ELSE NULL
    END;
    
    
-- Loading the Products table    
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Supply Chain Project/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(ProductId, ProductName, Category, SupplierId, UnitPrice_NGN, @StockQuantityVar, @ProductStatusVar, @LaunchDateVar, @Weight_KgVar)
SET
    StockQuantity = NULLIF(TRIM(@StockQuantityVar), ''),
    ProductStatus = NULLIF(TRIM(@ProductStatusVar), ''),
    LaunchDate = STR_TO_DATE(NULLIF(TRIM(@LaunchDateVar), ''), '%Y/%m/%d'), -- Use this ONLY after standardizing dates in CSV
    Weight_Kg = CASE
        WHEN TRIM(@Weight_KgVar) = '' THEN NULL
        WHEN TRIM(@Weight_KgVar) REGEXP '^[+-]?[0-9]+(\\.[0-9]+)?$' THEN CONVERT(TRIM(@Weight_KgVar), DECIMAL(10, 2))
        ELSE NULL
    END;
    

-- Loading the Order Items table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Supply Chain Project/order_items.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(OrderItemID, OrderID, ProductID, Quantity, @UnitPriceAtPurchaseVar, @TotalItemPriceVar, @ReturnStatusVar)
SET
    UnitPriceAtPurchase_NGN = CASE
        WHEN TRIM(@UnitPriceAtPurchaseVar) = '' THEN NULL
        WHEN TRIM(@UnitPriceAtPurchaseVar) REGEXP '^[+-]?[0-9]+(\\.[0-9]+)?$' THEN CONVERT(TRIM(@UnitPriceAtPurchaseVar), DECIMAL(10, 2))
        ELSE NULL
    END,
    TotalItemPrice_NGN = CASE
        WHEN TRIM(@TotalItemPriceVar) = '' THEN NULL
        WHEN TRIM(@TotalItemPriceVar) REGEXP '^[+-]?[0-9]+(\\.[0-9]+)?$' THEN CONVERT(TRIM(@TotalItemPriceVar), DECIMAL(10, 2))
        ELSE NULL
    END,
    ReturnStatus = NULLIF(TRIM(@ReturnStatusVar), '');
    