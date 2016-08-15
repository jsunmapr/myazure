-- Works against data in wasb://files@maprpublic.blob.core.windows.net/big-data-benchmark/
--
-- Create a table in local hive store
-- Create external table pointing to the data in S3 
-- Copy the data from WASB into local hive store
-- Create a MapR table (only works in M7 is enabled)
-- Copy data from local table to MapR table
--
-- TBD : run queries against all instances to evaluate performance.
--

-- CREATE DATABASE IF NOT EXISTS mapr_bdb ;
-- USE mapr_bdb ;

DROP TABLE IF EXISTS rankings ;

CREATE TABLE IF NOT EXISTS rankings 
	(pageURL STRING, pageRank INT, avgDuration INT) ;

DROP TABLE IF EXISTS rankings_wasb ;

CREATE EXTERNAL TABLE IF NOT EXISTS rankings_wasb
	(pageURL STRING, pageRank INT, avgDuration INT) 
	ROW FORMAT DELIMITED 
	FIELDS TERMINATED BY ',' 
	LINES TERMINATED BY '\n' 
	STORED AS TEXTFILE 
	LOCATION "wasb://files@maprpublic.blob.core.windows.net/big-data-benchmark/text/1node/rankings/" ;

INSERT OVERWRITE TABLE rankings
	select * from rankings_wasb ;


DROP TABLE IF EXISTS rankings_mapr ;

CREATE TABLE rankings_mapr (pageURL string, pageRank int, avgDuration int)
	STORED BY 'org.apache.hadoop.hive.hbase.HBaseStorageHandler'
	WITH SERDEPROPERTIES ("hbase.columns.mapping" = "cf1:pageRank,cf1:avgDuration")
	TBLPROPERTIES ("hbase.table.name" = "/user/mapr/rankings") ;

INSERT OVERWRITE TABLE rankings_mapr
	select * from rankings ;


