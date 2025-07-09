CREATE OR REPLACE PROCEDURE gold.export_all_tables_to_csv()
LANGUAGE 'plpgsql'
AS $$
DECLARE
	tbl RECORD;
	filename TEXT;
	export_sql TEXT;
BEGIN
	FOR tbl IN 
			SELECT table_name 
			FROM information_schema.tables
			WHERE table_schema = 'gold' AND table_type = 'VIEW'

	LOOP
		filename := 'C:/Projects/supplychain_cleansed_data/' || tbl.table_name ||'.csv';

		export_sql := FORMAT(
					'COPY (SELECT * FROM gold.%I) TO %L WITH (FORMAT CSV, HEADER, DELIMITER '','');',
					tbl.table_name,
					filename
		);

		EXECUTE export_sql;
	END LOOP;
END;
$$;

CALL gold.export_all_tables_to_csv();