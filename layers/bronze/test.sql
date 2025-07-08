-- ===============================
-- cleansing customers
-- ===============================
SELECT
	*
FROM
	bronze.customers;

-- Check for duplicates in bronze.customers table
SELECT
	customerid,
	COUNT(*)
FROM
	bronze.customers
GROUP BY
	customerid
HAVING
	COUNT(*) > 1;

-- Unwanted spaces
SELECT
	address
FROM
	bronze.customers
WHERE
	address != TRIM(address);

-- Distinct values
SELECT DISTINCT
	UPPER(TRIM(customersegment))
FROM
	bronze.customers
	-- discarding duplicate data
SELECT
	*
FROM
	bronze.customers customerid NOT LIKE '%D%';

-- ===============================
-- cleansing orders
-- ===============================
SELECT
	*
FROM
	bronze.orders;

-- vailidity
SELECT
	*
FROM
	bronze.orders
WHERE
	customerid NOT IN (
		SELECT
			customerid
		FROM
			silver.customers
	);

-- check for duplicates
SELECT
	orderid,
	COUNT(*)
FROM
	bronze.orders
GROUP BY
	orderid
HAVING
	COUNT(*) > 1;

-- Consistency
SELECT
	orderdate
FROM
	bronze.orders
WHERE
	orderdate !~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$';

SELECT
	shipdate
FROM
	bronze.orders
WHERE
	shipdate !~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$';

SELECT
	expecteddeliverydate
FROM
	bronze.orders
WHERE
	expecteddeliverydate !~ '^\d{4}-\d{2}-\d{2}$';

SELECT
	actualdeliverydate
FROM
	bronze.orders
WHERE
	actualdeliverydate !~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$';

SELECT
	orderdate,
	CASE
		WHEN orderdate ~ 'Invalid Date String' THEN NULL::TIMESTAMP
		WHEN orderdate ~ '^\d{2}/\d{2}/\d{4} \d{2}:\d{2}$' THEN TO_TIMESTAMP(orderdate, 'MM/DD/YYYY HH24:MI')::TIMESTAMP
		WHEN orderdate ~ '^\d{2}-[A-Za-z]{3}-\d{4} \d{2}:\d{2}[AP]M$' THEN TO_TIMESTAMP(orderdate, 'DD-Mon-YYYY HH12:MIAM')::TIMESTAMP
		WHEN orderdate ~ '^\d{14}$' THEN TO_TIMESTAMP(orderdate, 'YYYYMMDDHH24MISS')::TIMESTAMP
		ELSE orderdate::TIMESTAMP
	END AS new_orderdate,
	shipdate,
	CASE
		WHEN shipdate ~ 'Invalid Date String' THEN NULL::TIMESTAMP
		WHEN shipdate ~ '^\d{2}/\d{2}/\d{4} \d{2}:\d{2}$' THEN TO_TIMESTAMP(shipdate, 'MM/DD/YYYY HH24:MI')::TIMESTAMP
		WHEN shipdate ~ '^\d{2}-[A-Za-z]{3}-\d{4} \d{2}:\d{2}[AP]M$' THEN TO_TIMESTAMP(shipdate, 'DD-Mon-YYYY HH12:MIAM')::TIMESTAMP
		WHEN shipdate ~ '^\d{14}$' THEN TO_TIMESTAMP(shipdate, 'YYYYMMDDHH24MISS')::TIMESTAMP
		ELSE shipdate::TIMESTAMP
	END AS new_shipdate
FROM
	bronze.orders
WHERE
	orderdate !~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$';

-- DISTINCT
SELECT DISTINCT
	UPPER(TRIM(orderstatus))
FROM
	bronze.orders;

SELECT DISTINCT
	UPPER(TRIM(orderstatus)),
	CASE
		WHEN UPPER(TRIM(orderstatus)) LIKE 'DELIVERED%' THEN 'DELIVERED'
		WHEN UPPER(TRIM(orderstatus)) LIKE 'CANCEL%' THEN 'CANCELLED'
		WHEN UPPER(TRIM(orderstatus)) LIKE 'PENDING%' THEN 'PENDING'
		WHEN UPPER(TRIM(orderstatus)) LIKE 'RETURNED%' THEN 'RETURNED'
		WHEN UPPER(TRIM(orderstatus)) LIKE 'SHIPPED%' THEN 'SHIPPED'
		WHEN UPPER(TRIM(orderstatus)) LIKE 'PARTIALLY SHIPPED%' THEN 'PARTIALLY SHIPPED'
		WHEN UPPER(TRIM(orderstatus)) LIKE 'PROCESSING%' THEN 'PROCESSING'
	END AS new_orderstatus
FROM
	bronze.orders;

-- UNWANTED SPACES
SELECT
	shippingmethod
FROM
	bronze.orders
WHERE
	TRIM(shippingmethod) !~ shippingmethod;

SELECT DISTINCT
	paymentmethod
FROM
	bronze.orders
WHERE
	TRIM(paymentmethod) !~ paymentmethod;

SELECT
	shippingstate
FROM
	bronze.orders
WHERE
	TRIM(shippingstate) !~ shippingstate
	AND shippingstate IS NULL
	AND shippingstate ~ ' ';

SELECT DISTINCT
	paymentmethod,
	CASE
		WHEN UPPER(TRIM(paymentmethod)) LIKE 'CREDIT%' THEN 'CREDIT CARD'
		WHEN UPPER(TRIM(paymentmethod)) LIKE 'CASH%' THEN 'CASH ON DELIVERY (PH ONLY)'
		WHEN UPPER(TRIM(paymentmethod)) LIKE 'BANK%' THEN 'BANK TRANSFER'
		WHEN UPPER(TRIM(paymentmethod)) LIKE 'USSD%' THEN 'USSD'
		WHEN UPPER(TRIM(paymentmethod)) LIKE 'CARD%' THEN 'CARD(PAYSTACK/FLUTTERWAVE)'
		WHEN UPPER(TRIM(paymentmethod)) LIKE 'PAYPAL%' THEN 'PAYPAL'
		ELSE 'UNKNOWN'
	END AS new_pay_method
FROM
	bronze.orders;

SELECT DISTINCT
	paymentstatus,
	CASE
		WHEN UPPER(TRIM(PaymentStatus)) LIKE 'AUTHORIZED%' THEN 'AUTHORIZED'
		WHEN UPPER(TRIM(PaymentStatus)) LIKE 'PAID%' THEN 'PAID'
		WHEN UPPER(TRIM(PaymentStatus)) LIKE 'FAILED%' THEN 'FAILED'
		WHEN UPPER(TRIM(PaymentStatus)) LIKE 'PENDING%' THEN 'PENDING PAYMENT'
		WHEN UPPER(TRIM(PaymentStatus)) LIKE 'REFUNDED%' THEN 'REFUNDED'
		ELSE 'UNKNOWN'
	END AS new_status
FROM
	bronze.orders
WHERE
	TRIM(paymentstatus) !~ paymentstatus;

-- NORMALIZATION
SELECT
	totalamount_ngn,
	ROUND(totalamount_ngn::NUMERIC, 2) AS totalamount_ngn
FROM
	bronze.orders
	-- ===============================
	-- cleansing suppliers
	-- ===============================
SELECT
	*
FROM
	bronze.suppliers
	-- duplicate value check
SELECT
	contactemail,
	COUNT(*)
FROM
	bronze.suppliers
GROUP BY
	contactemail
HAVING
	COUNT(*) > 1;

-- unwanted spaces 
SELECT
	region
FROM
	bronze.suppliers
WHERE
	region !~ TRIM(region);

-- unique
SELECT DISTINCT
	supplierrating,
	COALESCE(
		(REGEXP_MATCH(supplierrating, '(\d(\.\d)?)')) [1]::FLOAT,
		0
	) AS rating
FROM
	bronze.suppliers;

SELECT
	phone,
	CASE
		WHEN LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) > 10
		AND REGEXP_REPLACE(phone, '[^0-9]', '', 'g') LIKE '1%' THEN '+1 ' || SUBSTRING(
			REGEXP_REPLACE(phone, '[^0-9]', '', 'g')
			FROM
				2 FOR 10
		)
		WHEN LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) = 10 THEN REGEXP_REPLACE(phone, '[^0-9]', '', 'g')
		WHEN LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) > 10
		AND REGEXP_REPLACE(phone, '[^0-9]', '', 'g') LIKE '0%' THEN SUBSTRING(
			REGEXP_REPLACE(phone, '[^0-9]', '', 'g')
			FROM
				2 FOR 10
		)
		ELSE SUBSTRING(
			REGEXP_REPLACE(phone, '[^0-9]', '', 'g')
			FROM
				1 FOR 10
		)
	END AS phone_N
FROM
	bronze.suppliers;

-- ==================================
-- Cleansing products
-- ==================================
SELECT
	*
FROM
	bronze.products;

-- duplicate check
SELECT
	productid,
	COUNT(*)
FROM
	bronze.products
GROUP BY
	productid
HAVING
	COUNT(*) > 1;

-- consitency check
SELECT
	*
FROM
	bronze.products
WHERE
	supplIerid NOT IN (
		SELECT
			supplierid
		FROM
			bronze.suppliers
	);

-- unwanted spaces 
SELECT
	category
FROM
	bronze.products
WHERE
	category !~ TRIM(category)
	-- invalid check
SELECT
	*
FROM
	bronze.products;

WHERE
	productid IN (
		SELECT
			productid
		FROM
			bronze.products
		WHERE
			unitprice < 0
	);

--Unique values check
SELECT DISTINCT
	productstatus,
FROM
	bronze.products;

-- consistency in launchdate
SELECT
	launchdate
FROM
	silver.products
WHERE
	launchdate ~ '^\d{2}/\d{2}/\d{4}';

-- =================================
-- Cleansing orderitem 
-- =================================
SELECT
	*
FROM
	silver.order_items;

-- invalid data check
SELECT
	*
FROM
	bronze.order_items
WHERE
	quantity < 1;

-- calculating the totalitemprice_ngn to check invalid data 
SELECT
	*
FROM
	bronze.order_items
WHERE
	quantity::NUMERIC * unitpriceatpurchase_ngn::NUMERIC != totalitemprice_ngn
	OR totalitemprice_ngn IS NULL
	AND quantity >= 1;