--Run this block inside postgres database
DROP DATABASE IF EXISTS Supplychain;
CREATE DATABASE Supplychain;

--STOP HERE, connect manually to `supplychain` database or use the \c supplychain (psql)
--run below for schema creation

-- ========================================
-- After connecting to `supplychain`, run:
-- ========================================

CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;
