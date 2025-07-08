CREATE OR REPLACE PROCEDURE bronze.load_bronze () LANGUAGE plpgsql AS $$
DECLARE 
	start_time TIMESTAMP;
	end_time TIMESTAMP;
BEGIN
	RAISE NOTICE '======================================================';
	RAISE NOTICE '                LOADIND BRONZE LAYER';
	RAISE NOTICE '======================================================';
	RAISE NOTICE ' ';
	RAISE NOTICE '------------------------------------------------------';
	RAISE NOTICE '                LOADING SOURCE TABLES';
	RAISE NOTICE '------------------------------------------------------';
	start_time:= clock_timestamp();
	RAISE NOTICE '>>> TRUNCATING TABLE bronze.suppliers';
	TRUNCATE TABLE bronze.suppliers;
	RAISE NOTICE '>>> INSERTING DATA INTO bronze.suppliers';
	COPY bronze.suppliers 
	FROM 'C:\Projects\postgres_imports_project_supply_chain\data\suppliers.csv'
	DELIMITER ','
	CSV HEADER;
	RAISE NOTICE '>>> INSERTED';
	RAISE NOTICE '------------';
	
	TRUNCATE TABLE bronze.orders;
	COPY bronze.orders
	FROM 'C:\Projects\postgres_imports_project_supply_chain\data\orders.csv'
	DELIMITER ','
	CSV HEADER;
	RAISE NOTICE '>>> TRUNCATING TABLE bronze.products';
	TRUNCATE TABLE bronze.products;
	RAISE NOTICE '>>> INSERTING DATA INTO bronze.products';
	COPY bronze.products
	FROM 'C:\Projects\postgres_imports_project_supply_chain\data\products.csv'
	DELIMITER ','
	CSV HEADER;
	RAISE NOTICE '>>> INSERTED';
	RAISE NOTICE '------------';
	
	RAISE NOTICE '>>> TRUNCATING TABLE bronze.customers';
	TRUNCATE TABLE bronze.customers;
	RAISE NOTICE '>>> INSERTING DATA INTO bronze.customers';
	COPY bronze.customers
	FROM 'C:\Projects\postgres_imports_project_supply_chain\data\customers.csv'
	DELIMITER ','
	CSV HEADER;
	RAISE NOTICE '>>> INSERTED';
	RAISE NOTICE '------------';
	
	RAISE NOTICE '>>> TRUNCATING TABLE bronze.order_items';
	TRUNCATE TABLE bronze.order_items;
	RAISE NOTICE '>>> INSERTING DATA INTO bronze.order_items';
	COPY bronze.order_items
	FROM 'C:\Projects\postgres_imports_project_supply_chain\data\order_items.csv'
	DELIMITER ','
	CSV HEADER;
	RAISE NOTICE '>>> INSERTED';
	end_time:= clock_timestamp();
	RAISE NOTICE '======================================================';
	RAISE NOTICE '           LOADED BRONZE LAYER SUCCESSFILLY';
	RAISE NOTICE '            Load duartion % seconds',EXTRACT (SECOND FROM (end_time - start_time));
	RAISE NOTICE '======================================================';
END;
$$;

CALL bronze.load_bronze ();