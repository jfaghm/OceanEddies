#!/bin/bash

# This script creates a database with all of the ocean eddies in a 
# single `eddies` table.  Dates get parsed into a Postgres `DATE`
# type and lat/lons are converted into the PostGIS POINT Geometry
# type.  We additionally build a BTREE index on the date and track_id columns
# and an RTREE index on the geometry column

# if [ ! -f eddies.csv ]; then
# 	echo "eddies.csv doesn't exist, creating..."
# 	if [ ! -f data/anticyc_simple.mat ]; then
# 		echo "Downloading eddies data..."
# 		wget "http://climatechange.cs.umn.edu/eddies/media/data/eddies_data_simple.tar.gz"
# 		tar -xvzf eddies_data_simple.tar.gz 
# 		mkdir data
# 		mv anticyc_simple.mat cyclonic_simple.mat data
# 	fi

# 	echo "Creating csv..."
# 	octave --eval "mat_to_csv()"
# fi

# if [ -z $(psql -lqt | cut -d \| -f 1 | grep ocean_eddies) ]; then
# 	echo "Database doesn't exist, creating it now..."
# 	createdb ocean_eddies
# 	psql ocean_eddies -c "CREATE EXTENSION postgis;" 
# fi

# psql ocean_eddies -c "DROP TABLE IF EXISTS eddies;"

# echo "CREATE TABLE eddies (
# 	track_id INTEGER NOT NULL, 
# 	lat FLOAT NOT NULL, 
# 	lon FLOAT NOT NULL, 
# 	date INTEGER NOT NULL, 
# 	surface_area FLOAT NOT NULL, 
# 	amplitude FLOAT NOT NULL, 
# 	radius FLOAT NOT NULL, 
# 	mean_geo_speed FLOAT NOT NULL
# );" | psql ocean_eddies

# echo "Copying CSV to Postgres..."
# psql ocean_eddies -c "\\copy eddies FROM '$(pwd)/eddies.csv' WITH CSV HEADER;"


# echo "Adding geometry column..."
# psql ocean_eddies -c "SELECT AddGeometryColumn('public', 'eddies', 'geom', 4326, 'POINT', 2);"
# psql ocean_eddies -c "UPDATE eddies SET geom=ST_GeomFromText('POINT(' || lon || ' ' || lat || ')', 4326);"

# echo "Parsing dates..."
# psql ocean_eddies -c "ALTER TABLE eddies ALTER COLUMN date TYPE DATE USING to_date(date::text, 'YYYYMMDD');"

# echo "Creating BTREE index on date column..."
# psql ocean_eddies -c "CREATE INDEX ON eddies (date);"

# echo "Creating BTREE index on track_id column..."
# psql ocean_eddies -c "CREATE INDEX ON eddies (track_id);"

# echo "Creating RTREE index on geom column..."
# psql ocean_eddies -c 'CREATE INDEX ON eddies USING GIST(geom);'

# psql ocean_eddies -c "ALTER TABLE eddies DROP COLUMN lat;"
# psql ocean_eddies -c "ALTER TABLE eddies DROP COLUMN lon;"


echo "Adding hurricane data..."

if [ ! -f data/atlantic_storms.csv ]; then
	wget -O data/atlantic_storms.csv "https://raw.githubusercontent.com/ResidentMario/hurdat2/master/data/atlantic_storms.csv"
fi

if [ ! -f data/pacific_storms.csv ]; then
	wget -O data/pacific_storms.csv "https://raw.githubusercontent.com/ResidentMario/hurdat2/master/data/pacific_storms.csv"
fi

echo "
	DROP TABLE IF EXISTS atlantic_storms;
	DROP TABLE IF EXISTS pacific_storms;
" | psql ocean_eddies

echo "CREATE TABLE atlantic_storms (
	index INTEGER, 
	id VARCHAR(8), 
	name VARCHAR(10), 
	date TIMESTAMP WITHOUT TIME ZONE, 
	record_identifier TEXT, 
	status_of_system TEXT, 
	latitude FLOAT, 
	longitude FLOAT, 
	maximum_sustained_wind_knots INTEGER, 
	maximum_pressure INTEGER, 
	kt_ne_34 INTEGER, 
	kt_se_34 INTEGER, 
	kt_sw_34 INTEGER, 
	kt_nw_34 INTEGER, 
	kt_ne_50 INTEGER, 
	kt_se_50 INTEGER, 
	kt_sw_50 INTEGER, 
	kt_nw_50 INTEGER, 
	kt_ne_64 INTEGER, 
	kt_se_64 INTEGER, 
	kt_sw_64 INTEGER, 
	kt_nw_64 INTEGER
);" | psql ocean_eddies

psql ocean_eddies -c "CREATE TABLE pacific_storms AS (SELECT * FROM atlantic_storms);"

psql ocean_eddies -c "\\copy atlantic_storms FROM '$(pwd)/data/atlantic_storms.csv' WITH CSV HEADER;"
psql ocean_eddies -c "\\copy pacific_storms FROM '$(pwd)/data/pacific_storms.csv' WITH CSV HEADER;"

echo "
	SELECT AddGeometryColumn ('public','atlantic_storms','geom',4326,'POINT',2);
	SELECT AddGeometryColumn ('public','pacific_storms','geom',4326,'POINT',2);
	UPDATE atlantic_storms SET geom=ST_GeomFromText('POINT(' || longitude || ' ' || latitude || ')', 4326);
	UPDATE pacific_storms SET geom=ST_GeomFromText('POINT(' || longitude || ' ' || latitude || ')', 4326);
" | psql ocean_eddies

echo "
	DROP TABLE IF EXISTS storms;
	CREATE TABLE storms AS SELECT *, 'atlantic'::text as region FROM atlantic_storms;
	INSERT INTO storms SELECT *, 'pacific'::text as region FROM pacific_storms;
	CREATE INDEX ON storms USING GIST(geom);
	DROP TABLE atlantic_storms;
	DROP TABLE pacific_storms;
" | psql ocean_eddies


