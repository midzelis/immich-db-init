#!/usr/bin/env bash

psql -a -d "$INIT_POSTGRES_DBNAME" -c "CREATE EXTENSION IF NOT EXISTS vectors;"
psql -a -d "$INIT_POSTGRES_DBNAME" -c "CREATE EXTENSION IF NOT EXISTS earthdistance CASCADE;"
psql -a -d "$INIT_POSTGRES_DBNAME" -c "ALTER DATABASE \"$INIT_POSTGRES_DBNAME\" SET search_path TO \"\$user\", public, vectors;"
psql -a -d "$INIT_POSTGRES_DBNAME" -c "GRANT ALL ON SCHEMA vectors TO \"$INIT_POSTGRES_USER\";"
psql -a -d "$INIT_POSTGRES_DBNAME" -c "GRANT SELECT ON TABLE pg_vector_index_stat to \"$INIT_POSTGRES_USER\";"

exit 0
