/*
==========================================================================================================
Business problem:
----------------
Rapid growth in `port harcourt` market --> fulfilment breakdown --> threatening retention of new 
customers --> leadership want the product-level, supplier-level, and customer level insights.

Objectives of stakeholders:
--------------------------
1.  Product avaialbility bottleneck: Identify which of the 200 products are most frequently out 
of stock or are major contributors to Cancelled orders, especially for shipments to Port 
Harcourt and surrounding areas, despite the high order volume. in simple words, What's 
OUT-OF-STOCK or dive cancellation of orders

2.	Customer Impact: Determine if fulfillment issues (e.g., significant delays where Actual 
Delivery Date far exceeds ExpectedDeliveryDate, or high cancellation rates) are disproportion-
ately affecting customers acquired since March 2024 (RegistrationDate > 2024-03-01), and if 
this correlates with lower initial repeat purchase rates from these new customers

3.	Identify Top Supplier-Related Fulfillment Constraints: For the limited set of 15 suppliers, 
determine which ones are linked to the products experiencing the most severe availability 
gaps or quality issues (inferred from ReturnStatus) that impede smooth order fulfillment to 
the Port Harcourt market.
==========================================================================================================
*/
/*
===============================================
Pinpoint Key Product Availability Gaps in order
words, Product availablitiy bottlenect
===============================================
*/
WITH
	product_order_stats AS (
		SELECT
			p.productid,
			p.productname,
			COUNT(*) AS total_orders,
			COUNT(*) FILTER (
				WHERE
					o.orderstatus = 'CANCELLED'
			) AS total_cancels,
			ROUND(
				COUNT(*) FILTER (
					WHERE
						o.orderstatus = 'CANCELLED'
				) * 100.0 / COUNT(*),
				2
			) AS cancel_rate,
			COUNT(*) FILTER (
				WHERE
					p.productstatus = 'OUTOFSTOCK'
					AND o.orderstatus = 'CANCELLED'
			) AS outofstock_cancels,
			ROUND(
				COUNT(*) FILTER (
					WHERE
						p.productstatus = 'OUTOFSTOCK'
						AND o.orderstatus = 'CANCELLED'
				) * 100.0 / COUNT(*),
				2
			) AS outofstock_cancels_rate,
			COUNT(*) FILTER (
				WHERE
					p.stockhealth = 'Null Stock'
					AND o.orderstatus = 'CANCELLED'
			) AS missing_stock_cancels,
			COUNT(*) FILTER (
				WHERE
					p.stockhealth = 'Negative Stock'
					AND o.orderstatus = 'CANCELLED'
			) AS invalid_stock_cancels,
			COUNT(*) FILTER (
				WHERE
					p.productstatus = 'ACTIVE'
					AND o.paymentstatus != 'PAILD'
					AND o.orderstatus = 'CANCELLED'
			) AS payment_issue_cancels
		FROM
			silver.orders o
			JOIN silver.order_items oi ON oi.orderid = o.orderid
			JOIN silver.products p ON p.productid = oi.productid
		WHERE
			o.shippingcity = 'Port Harcourt'
		GROUP BY
			p.productid,
			p.productname
	),
	with_demand_flag AS (
		SELECT
			*,
			CUME_DIST() OVER (
				ORDER BY
					total_orders DESC
			) AS distribution
		FROM
			product_order_stats
	)
SELECT
	productid,
	productname,
	total_orders,
	cancel_rate AS cancel_rate_percent,
	outofstock_cancels,
	outofstock_cancels_rate AS outofstock_cancels_rate_percent,
	missing_stock_cancels,
	invalid_stock_cancels
FROM
	with_demand_flag
WHERE
	distribution <= 0.20
	AND cancel_rate > 20
ORDER BY
	cancel_rate DESC,
	total_cancels;

/*
=============================================
Customer Impact Analysis
=============================================
*/

WITH
	customer_cohorts AS (
		SELECT
			o.orderid,
			o.customerid,
			c.registrationdate,
			CASE
				WHEN registrationdate > '2024-03-01' THEN 'New'
				ELSE 'Existing'
			END AS cohort,
			o.orderstatus,
			o.expecteddeliverydate,
			o.actualdeliverydate,
			CASE
				WHEN o.orderstatus = 'CANCELLED' THEN 1
				ELSE 0
			END AS is_cancelled,
			CASE
				WHEN (
					o.actualdeliverydate::DATE - o.expecteddeliverydate::DATE
				) > (
					SELECT
						ROUND(
							AVG(
								o.actualdeliverydate::DATE - o.expecteddeliverydate::DATE
							),
							1
						) AS avg_delay
					FROM
						silver.orders o
					WHERE
						o.actualdeliverydate::DATE - o.expecteddeliverydate::DATE >= 0
				) THEN 'Late delivery'
				WHEN o.actualdeliverydate::DATE IS NULL
				AND o.expecteddeliverydate::DATE IS NOT NULL THEN 'Not deliverd'
				WHEN o.actualdeliverydate::DATE IS NULL
				AND o.expecteddeliverydate::DATE IS NULL THEN 'Cancelled'
				ELSE 'Intime delivey'
			END AS delivery_status
		FROM
			silver.orders o
			JOIN silver.customers c ON c.customerid = o.customerid
	),
	repeated_customers AS (
		SELECT
			customer_orders.cohort,
			COUNT(customer_orders.customerid) AS total_customers,
			COUNT(customer_orders.customerid) FILTER (
				WHERE
					orders_count > 1
			) AS repeated_customers_count
		FROM
			(
				SELECT
					customerid,
					cohort,
					COUNT(*) AS orders_count
				FROM
					customer_cohorts
				GROUP BY
					customerid,
					cohort
			) customer_orders
		GROUP BY
			customer_orders.cohort
	),
	cohort_stats AS (
		SELECT
			c.cohort,
			COUNT(*) AS total_orders,
			SUM(is_cancelled) AS cancelled_orders,
			ROUND(SUM(is_cancelled) * 100.0 / COUNT(*), 2) AS cancel_rate,
			ROUND(
				SUM(
					CASE
						WHEN delivery_status = 'Late delivery' THEN 1
					END
				) * 100.0 / COUNT(*),
				2
			) AS late_delivery_rate
		FROM
			customer_cohorts c
		GROUP BY
			c.cohort
	)
SELECT
	c.cohort,
	r.total_customers,
	r.repeated_customers_count AS repeated_customers,
	ROUND(
		r.repeated_customers_count * 100.0 / r.total_customers,
		2
	) AS repeated_customers_percent,
	c.total_orders,
	c.cancelled_orders,
	c.cancel_rate,
	c.late_delivery_rate
FROM
	cohort_stats c
	JOIN repeated_customers r ON r.cohort = c.cohort;

/*
======================================================
Identify Top Supplier-Related Fulfillment Constraints
======================================================
*/
SELECT
	p.supplierid,
	COUNT(p.productid) AS products_supplied,
	SUM(
		CASE
			WHEN p.productstatus = 'OUTOFSTOCK' THEN 1
			ELSE 0
		END
	) AS products_outofstock_count,
	COUNT(*) FILTER (
		WHERE
			o.orderstatus = 'CANCELLED'
	) AS total_cancelled_products,
	COUNT(*) FILTER (
		WHERE
			p.productstatus = 'OUTOFSTOCK'
			AND o.orderstatus = 'CANCELLED'
	) AS cancel_dueto_outofstock,
	COUNT(*) FILTER (
		WHERE
			p.productstatus = 'ACTIVE'
			AND o.paymentstatus != 'PAILD'
			AND o.orderstatus = 'CANCELLED'
	) AS cancel_dueto_notpaid,
	COUNT(*) FILTER (
		WHERE
			p.productstatus = 'ACTIVE'
			AND o.actualdeliverydate::DATE > o.expecteddeliverydate::DATE
			AND o.orderstatus = 'CANCELLED'
	) AS due_to_delays_cancel,
	COUNT(*) FILTER (
		WHERE
			oi.returnstatus = 'Completed'
	) AS total_returned,
	COUNT(*) FILTER (
		WHERE
			oi.returnstatus = 'Approved'
	) AS total_return_approved,
	COUNT(*) FILTER (
		WHERE
			p.stockhealth = 'Negative Stock'
	) AS total_invalid_stocks
FROM
	silver.orders o
	JOIN silver.order_items oi ON oi.orderid = o.orderid
	JOIN silver.products p ON p.productid = oi.productid
	JOIN silver.suppliers s ON s.supplierid = p.supplierid
WHERE
	o.shippingcity = 'Port Harcourt'
GROUP BY
	1
ORDER BY
	products_supplied DESC,
	products_outofstock_count DESC;

SELECT DISTINCT
	returnstatus
FROM
	silver.order_items