#!/bin/bash

# This script creates a database with all of the ocean eddies in a 
# single `eddies` table.  Dates get parsed into a Postgres `DATE`
# type and lat/lons are converted into the PostGIS POINT Geometry
# type.  We additionally build a BTREE index on the date and track_id columns
# and an RTREE index on the geometry column

if [ ! -f eddies.csv ]; then
	echo "eddies.csv doesn't exist, creating..."
	if [ ! -f data/anticyc_simple.mat ]; then
		echo "Downloading eddies data..."
		wget "http://climatechange.cs.umn.edu/eddies/media/data/eddies_data_simple.tar.gz"
		tar -xvzf eddies_data_simple.tar.gz 
		mkdir data
		mv anticyc_simple.mat cyclonic_simple.mat data
	fi

	echo "Creating csv..."
	octave --eval "mat_to_csv()"
fi

if [ -z $(psql -lqt | cut -d \| -f 1 | grep ocean_eddies) ]; then
	echo "Database doesn't exist, creating it now..."
	createdb ocean_eddies
	psql ocean_eddies -c "CREATE EXTENSION postgis;" 
fi

psql ocean_eddies -c "DROP TABLE IF EXISTS eddies;"

echo "CREATE TABLE eddies (
	track_id INTEGER NOT NULL, 
	lat FLOAT NOT NULL, 
	lon FLOAT NOT NULL, 
	date INTEGER NOT NULL, 
	surface_area FLOAT NOT NULL, 
	amplitude FLOAT NOT NULL, 
	radius FLOAT NOT NULL, 
	mean_geo_speed FLOAT NOT NULL
);" | psql ocean_eddies

echo "Copying CSV to Postgres..."
psql ocean_eddies -c "\\copy eddies FROM '$(pwd)/eddies.csv' WITH CSV HEADER;"


echo "Adding geometry column..."
psql ocean_eddies -c "SELECT AddGeometryColumn('public', 'eddies', 'geom', 4326, 'POINT', 2);"
psql ocean_eddies -c "UPDATE eddies SET geom=ST_GeomFromText('POINT(' || lon || ' ' || lat || ')', 4326);"

echo "Parsing dates..."
psql ocean_eddies -c "ALTER TABLE eddies ALTER COLUMN date TYPE DATE USING to_date(date::text, 'YYYYMMDD');"

echo "Creating BTREE index on date column..."
psql ocean_eddies -c "CREATE INDEX ON eddies (date);"

echo "Creating BTREE index on track_id column..."
psql ocean_eddies -c "CREATE INDEX ON eddies (track_id);"

echo "Creating RTREE index on geom column..."
psql ocean_eddies -c 'CREATE INDEX ON eddies USING GIST(geom);'

psql ocean_eddies -c "ALTER TABLE eddies DROP COLUMN lat;"
psql ocean_eddies -c "ALTER TABLE eddies DROP COLUMN lon;"