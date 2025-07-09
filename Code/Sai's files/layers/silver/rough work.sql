SELECT
	*
FROM
	silver.order_items;

SELECT
	*
FROM
	silver.orders
WHERE
	orderid IN (
		SELECT
			orderid
		FROM
			bronze.order_items
		WHERE
			quantity < 1
	);

SELECT
	*
FROM
	bronze.order_items
WHERE
	orderid = 'ORD00596';

SELECT
	paymentstatus,
	discountamount_ngn,
	totalamount_ngn
FROM
	silver.orders
WHERE
	orderid = 'ORD00596';

-- REFUNDED, FAILED
SELECT
	406146.66 + 199363.94 + 5412.76 AS value_;

-- 610923.36  613206.00
-- ORD00113 6535.19
-- ORD00140 6291.19 
SELECT
	2 * 2706.38 + 2346.05
SELECT
	*
FROM
	silver.products;

WHERE
	productid = 'P0004';

SELECT
	267731.88 + 671553.06 + 705013.00 + 2991.84 + 345338.84;

--1992628.62
SELECT DISTINCT
	returnstatus
FROM
	bronze.order_items
SELECT
	*
FROM
	bronze.order_items
WHERE
	(
		quantity <= 0
		OR quantity IS NULL
	)
	AND (totalitemprice_ngn IS NULL)
	AND returnstatus = 'Completed';