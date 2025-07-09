CREATE OR REPLACE PROCEDURE silver.load_silver () LANGUAGE plpgsql AS $$
DECLARE 
	start_time TIMESTAMP;
	end_time TIMESTAMP;
BEGIN
	RAISE NOTICE '=============================================================';
	RAISE NOTICE '                   LOADING SILVER LAYER';
	RAISE NOTICE '=============================================================';
	RAISE NOTICE ' ';
	RAISE NOTICE '=============================================================';
	RAISE NOTICE '    LOADING TABLES FROM BRONZE LAYER --> SILVER LAYER';
	RAISE NOTICE '=============================================================';
	RAISE NOTICE ' ';	
	start_time := clock_timestamp();
	RAISE NOTICE '>>> TRUNCATING silver.customers ';
	TRUNCATE TABLE silver.customers;
	RAISE NOTICE '>>> INSERTING DATA INTO silver.customers';
	INSERT INTO silver.customers(
		customerid,
		firstname,
		lastname,
		email,
		address,
		city,
		postalcode,
		registrationdate,
		lastlogindate,
		customersegment,
		dateofbirth,
		phone,
		phone_extension
	)
	SELECT
		customerid,
		firstname,
		lastname,
		email,
		TRIM(address) AS address,
		city,
		COALESCE(postalcode, 'NA') AS postalcode,
		TO_DATE(registrationdate, 'MM/DD/YYYY') AS registrationdate,
		TO_TIMESTAMP(lastlogindate, 'MM/DD/YYY HH24:MI')::TIMESTAMP AS lastlogindate,
		CASE  
			WHEN UPPER(TRIM(customersegment)) LIKE 'VIP%' THEN 'VIP'
			WHEN UPPER(TRIM(customersegment)) LIKE 'PLATINUM%' THEN 'PLATINUM'
			WHEN UPPER(TRIM(customersegment)) LIKE 'GOLD%' THEN 'GOLD'
			WHEN UPPER(TRIM(customersegment)) LIKE 'NEW%' THEN 'NEW'
			WHEN UPPER(TRIM(customersegment)) LIKE 'STANDARD%' OR UPPER(TRIM(customersegment)) = 'STD.' THEN 'STANDARD'
			WHEN UPPER(TRIM(customersegment)) LIKE 'SILVER%' THEN 'SILVER'
			WHEN UPPER(TRIM(customersegment)) LIKE 'BRONZE%' THEN 'BRONZE'
			WHEN customersegment IS NULL THEN COALESCE(customersegment, 'UNCLASSIFIED')
			ELSE
			UPPER(TRIM(customersegment))
		END AS customersegment,
		TO_DATE(dateofbirth, 'MM/DD/YYYY') AS dateofbirth,
		CASE 
			WHEN LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) < 10 THEN NULL
			WHEN (REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) LIKE '1%' THEN '+1' || SUBSTRING(REGEXP_REPLACE(phone, '[^0-9]', '', 'g') FROM 1 FOR 10)
			WHEN (REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) LIKE '001%' THEN '+1' || SUBSTRING(REGEXP_REPLACE(phone, '[^0-9]', '', 'g') FROM 4 FOR 10)
			ELSE SUBSTRING(REGEXP_REPLACE(phone, '[^0-9]', '', 'g') FROM 1 FOR 10)
		END AS phone,
		CASE 
			WHEN (REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) LIKE '1%' AND LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) > 10 THEN SUBSTRING(REGEXP_REPLACE(phone, '[^0-9]', '', 'g') FROM 11 FOR LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '', 'g')))
			WHEN (REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) LIKE '001%' AND LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) > 10 THEN SUBSTRING(REGEXP_REPLACE(phone, '[^0-9]', '', 'g') FROM 14 FOR LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '', 'g')))
			WHEN LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) > 10 THEN SUBSTRING(REGEXP_REPLACE(phone, '[^0-9]', '', 'g') FROM 11 FOR LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '', 'g')))
			ELSE ' '
		END AS phone_extension
	FROM
		bronze.customers
	WHERE 
		customerid NOT LIKE '%D%';
	RAISE NOTICE '>>> INSERTED SUCCESSFULLY';
	RAISE NOTICE ' ';
	RAISE NOTICE '>>> TRUNCATING silver.orders ';
	TRUNCATE TABLE silver.orders;
	RAISE NOTICE '>>> INSERTING DATA INTO silver.orders';
	INSERT INTO silver.orders (
		orderid,
		customerid,
		orderdate,
		shipdate,
		expecteddeliverydate,
		actualdeliverydate,
		orderstatus,
		shippingmethod,
		shippingcost_ngn,
		shippingaddress,
		shippingcity,
		shippingstate,
		shippingpostalcode,
		shippingcountry,
		paymentmethod,
		paymentstatus,
		discountcode,
		discountamount_ngn,
		totalamount_ngn
	)
	SELECT
		orderid,
		customerid,
		CASE
			WHEN orderdate ~ 'Invalid Date String' THEN NULL::TIMESTAMP
			WHEN orderdate ~ '^\d{2}/\d{2}/\d{4} \d{2}:\d{2}$'
				THEN TO_TIMESTAMP(orderdate, 'MM/DD/YYYY HH24:MI')::TIMESTAMP
			WHEN orderdate ~ '^\d{2}-[A-Za-z]{3}-\d{4} \d{2}:\d{2}[AP]M$'
				THEN TO_TIMESTAMP(orderdate, 'DD-Mon-YYYY HH12:MIAM')::TIMESTAMP
			WHEN orderdate ~ '^\d{14}$'
				THEN TO_TIMESTAMP(orderdate, 'YYYYMMDDHH24MISS')::TIMESTAMP
			ELSE
				orderdate::TIMESTAMP
		END AS orderdate,
		CASE
			WHEN shipdate ~ 'Invalid Date String' THEN NULL::TIMESTAMP
			WHEN shipdate ~ '^\d{2}/\d{2}/\d{4} \d{2}:\d{2}$'
				THEN TO_TIMESTAMP(shipdate, 'MM/DD/YYYY HH24:MI')::TIMESTAMP
			WHEN shipdate ~ '^\d{2}-[A-Za-z]{3}-\d{4} \d{2}:\d{2}[AP]M$'
				THEN TO_TIMESTAMP(shipdate, 'DD-Mon-YYYY HH12:MIAM')::TIMESTAMP
			WHEN shipdate ~ '^\d{14}$'
				THEN TO_TIMESTAMP(shipdate, 'YYYYMMDDHH24MISS')::TIMESTAMP
			ELSE
				shipdate::TIMESTAMP
		END AS shipdate,
		expecteddeliverydate,
		CASE
			WHEN actualdeliverydate ~ 'Invalid Date String' THEN NULL::TIMESTAMP
			WHEN actualdeliverydate ~ '^\d{2}/\d{2}/\d{4} \d{2}:\d{2}$'
				THEN TO_TIMESTAMP(actualdeliverydate, 'MM/DD/YYYY HH24:MI')::TIMESTAMP
			WHEN actualdeliverydate ~ '^\d{2}-[A-Za-z]{3}-\d{4} \d{2}:\d{2}[AP]M$'
				THEN TO_TIMESTAMP(actualdeliverydate, 'DD-Mon-YYYY HH12:MIAM')::TIMESTAMP
			WHEN actualdeliverydate ~ '^\d{14}$'
				THEN TO_TIMESTAMP(actualdeliverydate, 'YYYYMMDDHH24MISS')::TIMESTAMP
			ELSE
				actualdeliverydate::TIMESTAMP
		END AS actualdeliverydate,
		CASE
			WHEN UPPER(TRIM(orderstatus)) LIKE 'DELIVERED%' THEN 'DELIVERED'
			WHEN UPPER(TRIM(orderstatus)) LIKE 'CANCEL%' THEN 'CANCELLED'
			WHEN UPPER(TRIM(orderstatus)) LIKE 'PENDING%' THEN 'PENDING'
			WHEN UPPER(TRIM(orderstatus)) LIKE 'RETURNED%' THEN 'RETURNED'
			WHEN UPPER(TRIM(orderstatus)) LIKE 'SHIPPED%' THEN 'SHIPPED'
			WHEN UPPER(TRIM(orderstatus)) LIKE 'PARTIALLY SHIPPED%' THEN 'PARTIALLY SHIPPED'
			WHEN UPPER(TRIM(orderstatus)) LIKE 'PROCESSING%' THEN 'PROCESSING'
		END AS orderstatus,
		CASE 
			WHEN UPPER(TRIM(shippingmethod)) LIKE 'STANDARD%' OR UPPER(TRIM(shippingmethod)) LIKE 'STD.' THEN 'STANDARD'
			WHEN UPPER(TRIM(shippingmethod)) LIKE 'INTERSTATE BUS%' THEN 'INTERSTATE BUS'
			WHEN UPPER(TRIM(shippingmethod)) LIKE 'EXPRESS%' THEN 'EXPRESS'
			WHEN UPPER(TRIM(shippingmethod)) LIKE 'LOCAL PICKUP (PH ONLY)%' THEN 'LOCAL PICKUP (PH ONLY)'
			ELSE UPPER(TRIM(shippingmethod))
		END AS shippingmethod,
		COALESCE(shippingcost_ngn, 0) AS shippingcost_ngn,
		shippingaddress,
		shippingcity,
		shippingstate,
		shippingpostalcode,
		shippingcountry,
		CASE 
			WHEN UPPER(TRIM(paymentmethod)) LIKE 'CREDIT%' THEN 'CREDIT CARD'
			WHEN UPPER(TRIM(paymentmethod)) LIKE 'CASH%' THEN 'CASH ON DELIVERY (PH ONLY)'
			WHEN UPPER(TRIM(paymentmethod)) LIKE 'BANK%' THEN 'BANK TRANSFER'
			WHEN UPPER(TRIM(paymentmethod)) LIKE 'USSD%' THEN 'USSD'
			WHEN UPPER(TRIM(paymentmethod)) LIKE 'CARD%' THEN 'CARD(PAYSTACK/FLUTTERWAVE)'
			WHEN UPPER(TRIM(paymentmethod)) LIKE 'PAYPAL%' THEN 'PAYPAL'
			ELSE 'UNKNOWN'
		END AS paymentmethod,
		CASE 
			WHEN UPPER(TRIM(PaymentStatus)) LIKE 'AUTHORIZED%' THEN 'AUTHORIZED'
			WHEN UPPER(TRIM(PaymentStatus)) LIKE 'PAID%' THEN 'PAID'
			WHEN UPPER(TRIM(PaymentStatus)) LIKE 'FAILED%' THEN 'FAILED'
			WHEN UPPER(TRIM(PaymentStatus)) LIKE 'PENDING%' THEN 'PENDING PAYMENT'
			WHEN UPPER(TRIM(PaymentStatus)) LIKE 'REFUNDED%' THEN 'REFUNDED'
			ELSE 'UNKNOWN'
		END AS paymentstatus,
		COALESCE(discountcode, 'UNAVAILABLE') AS discountcode,
		COALESCE(discountamount_ngn, 0) AS discountamount_ngn,
		ROUND(totalamount_ngn::NUMERIC, 2) AS totalamount_ngn
	FROM
		bronze.orders;
	RAISE NOTICE '>>> INSERTED SUCCESSFULLY';
	RAISE NOTICE ' ';
	RAISE NOTICE '>>> TRUNCATING silver.suppliers';
	TRUNCATE TABLE silver.suppliers;
	RAISE NOTICE '>>> INSERTING DATA INTO silver.suppliers';
	INSERT INTO silver.suppliers(
		SupplierID,
		SupplierName,
		Country,
		Region,
		ContactEmail,
		Phone,
		YearsInBusiness,
		SupplierRating
	)
	SELECT 
		SupplierID,
		SupplierName,
		Country,
		COALESCE(Region, 'Unknown') AS Region,
		ContactEmail,
		CASE
			WHEN LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) > 10
			AND REGEXP_REPLACE(phone, '[^0-9]', '', 'g') LIKE '1%' 
			THEN '+1 ' || SUBSTRING(REGEXP_REPLACE(phone, '[^0-9]', '', 'g') FROM 2 FOR 10)
			WHEN LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) = 10 THEN REGEXP_REPLACE(phone, '[^0-9]', '', 'g')
			WHEN LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) > 10 
			AND REGEXP_REPLACE(phone, '[^0-9]', '', 'g') LIKE '0%' 
			THEN SUBSTRING(REGEXP_REPLACE(phone, '[^0-9]', '', 'g') FROM 2 FOR 10)
			ELSE SUBSTRING(REGEXP_REPLACE(phone, '[^0-9]', '', 'g') FROM 1 FOR 10)
		END AS phone,
		COALESCE(YearsInBusiness::NUMERIC, 0)::INTEGER AS YearsInBusiness,
		COALESCE((REGEXP_MATCH(supplierrating, '(\d(\.\d)?)'))[1]::NUMERIC, 0) AS supplierrating
	FROM
		bronze.suppliers;
	RAISE NOTICE '>>> INSERTED SUCCESSFULLY';
	RAISE NOTICE ' ';
	RAISE NOTICE '>>> TRUNCATING silver.products ';
	TRUNCATE TABLE silver.products;
	RAISE NOTICE '>>> INSERTING DATA INTO silver.products ';
	INSERT INTO silver.products
	(
		ProductID,
		ProductName,
		Category,
		SupplierID,
		UnitPrice,
		StockQuantity,
		ProductStatus,
		Stockhealth,
		StockAnomalyFlag,
		LaunchDate,
		Weight_kg
	)
	SELECT
		ProductID,
		ProductName,
		TRIM(category) AS category,
		SupplierID,
		ROUND(ABS(UnitPrice)::NUMERIC, 2) AS UnitPrice, 
		CASE WHEN StockQuantity < 0 OR StockQuantity IS NULL THEN 0
			 ELSE StockQuantity
		END AS StockQuantity,
		CASE 
			WHEN StockQuantity > 0 AND UPPER(ProductStatus) = 'OUTOFSTOCK' THEN 'ACTIVE'
			WHEN StockQuantity <= 0 THEN 'OUTOFSTOCK'
			ELSE UPPER(ProductStatus)
		END AS ProductStatus,
		CASE 
			WHEN StockQuantity < 0 THEN 'Negative Stock'
			WHEN StockQuantity = 0  THEN 'Zero Stock'
			WHEN  StockQuantity IS NULL THEN 'Null Stock'
			ELSE 'Healthy Stock'
		END AS StockHealth,
		CASE 
			WHEN StockQuantity < 0 AND Supplierid IN ('S002', 'S004', 'S005', 'S006', 'S007')THEN 'Supplier-specific Negative Stock'
			WHEN StockQuantity < 0 THEN 'Unexpected Negative stock'
			WHEN StockQuantity IS NULL THEN 'Missing'
			ELSE 'Valid'
		END AS StockAnomalyFlag,
		CASE 
			WHEN LaunchDate ~ '^\d{2}/\d{2}/\d{4}'
			THEN TO_DATE(LaunchDate, 'DD/MM/YYYY')::DATE
			ELSE LaunchDate::DATE
		END AS LaunchDate,
		Weight_kg
	FROM
		bronze.products;
	RAISE NOTICE '>>> INSERTED SUCCESSFULLY';
	RAISE NOTICE ' ';
	RAISE NOTICE '>>> TRUNCATING silver.order_items';
	TRUNCATE TABLE silver.order_items;
	RAISE NOTICE '>>> INSERTING DATA INTO silver.order_items';
	INSERT INTO silver.order_items
	(
		orderitemid,
		orderid,
		productid,
		quantity,
		unitpriceatpurchase_ngn,
		totalitemprice_ngn,
		returnstatus
	)
	SELECT 
		orderitemid,
		orderid,
		productid,
		CASE 
			WHEN quantity < 0 THEN 0
			ELSE quantity
		END AS quantity,
		ROUND(unitpriceatpurchase_ngn::NUMERIC, 2) AS unitpriceatpurchase_ngn,
		CASE 
			WHEN ((quantity::NUMERIC)*(unitpriceatpurchase_ngn::NUMERIC)) != totalitemprice_ngn OR (totalitemprice_ngn IS NULL AND quantity IS NOT NULL) THEN ROUND((quantity::NUMERIC)*(unitpriceatpurchase_ngn::NUMERIC), 2)
			ELSE totalitemprice_ngn::NUMERIC
		END AS totalitemprice_ngn, --calculate normalized  the totalitemprice_ngn if it is invalid
		COALESCE(returnstatus, 'Unknown') AS returnstatus
	FROM bronze.order_items;
	RAISE NOTICE '>>> INSERTED SUCCESSFULLY';
	RAISE NOTICE ' ';
	end_time := clock_timestamp();
	RAISE NOTICE ' ';
	RAISE NOTICE '=============================================================';
	RAISE NOTICE '                    SILVER LAYER LOADED';
	RAISE NOTICE '             LOADING DURATION: % seconds', EXTRACT(SECOND FROM end_time - start_time);
	RAISE NOTICE '=============================================================';
	RAISE NOTICE ' ';
END;
$$;

CALL silver.load_silver ();