#!/usr/bin/env bash

# adapted from https://github.com/onedr0p/containers/blob/main/apps/postgres-init/Dockerfile

# This is most commonly set to the user 'postgres'
export INIT_POSTGRES_SUPER_USER=${INIT_POSTGRES_SUPER_USER:-postgres}

# Strip quotes from port, if any
port_temp=${INIT_POSTGRES_PORT:-5432}
port_temp="${port_temp%\"}"
port_temp="${port_temp#\"}"
export INIT_POSTGRES_PORT=${port_temp}

if [[ -z "${INIT_POSTGRES_HOST}" ||
    -z "${INIT_POSTGRES_SUPER_PASS}" ||
    -z "${INIT_POSTGRES_USER}" ||
    -z "${INIT_POSTGRES_PASS}" ||
    -z "${INIT_POSTGRES_DBNAME}" ]] \
    ; then
    printf "\e[1;32m%-6s\e[m\n" "Invalid configuration - missing a required environment variable"
    [[ -z "${INIT_POSTGRES_HOST}" ]] && printf "\e[1;32m%-6s\e[m\n" "INIT_POSTGRES_HOST: unset"
    [[ -z "${INIT_POSTGRES_SUPER_PASS}" ]] && printf "\e[1;32m%-6s\e[m\n" "INIT_POSTGRES_SUPER_PASS: unset"
    [[ -z "${INIT_POSTGRES_USER}" ]] && printf "\e[1;32m%-6s\e[m\n" "INIT_POSTGRES_USER: unset"
    [[ -z "${INIT_POSTGRES_PASS}" ]] && printf "\e[1;32m%-6s\e[m\n" "INIT_POSTGRES_PASS: unset"
    [[ -z "${INIT_POSTGRES_DBNAME}" ]] && printf "\e[1;32m%-6s\e[m\n" "INIT_POSTGRES_DBNAME: unset"
    exit 1
fi

# These env are for the psql CLI
export PGHOST="${INIT_POSTGRES_HOST}"
export PGUSER="${INIT_POSTGRES_SUPER_USER}"
export PGPASSWORD="${INIT_POSTGRES_SUPER_PASS}"
export PGPORT="${INIT_POSTGRES_PORT}"

until pg_isready; do
    printf "\e[1;32m%-6s\e[m\n" "Waiting for Host '${PGHOST}' on port '${PGPORT}' ..."
    sleep 1
done

user_exists=$(
    psql \
        --tuples-only \
        --csv \
        --command "SELECT 1 FROM pg_roles WHERE rolname = '${INIT_POSTGRES_USER}'"
)

if [[ -z "${user_exists}" ]]; then
    printf "\e[1;32m%-6s\e[m\n" "Create User ${INIT_POSTGRES_USER} ..."
    createuser ${INIT_POSTGRES_USER_FLAGS} "${INIT_POSTGRES_USER}"
fi

printf "\e[1;32m%-6s\e[m\n" "Update password for user ${INIT_POSTGRES_USER} ..."
psql --command "alter user \"${INIT_POSTGRES_USER}\" with encrypted password '${INIT_POSTGRES_PASS}';"
database_exists=$(
    psql \
        --tuples-only \
        --csv \
        --command "SELECT 1 FROM pg_database WHERE datname = '${INIT_POSTGRES_DBNAME}'"
)
if [[ -z "${database_exists}" ]]; then
    printf "\e[1;32m%-6s\e[m\n" "Create Database ${INIT_POSTGRES_DBNAME} ..."
    createdb --owner "${INIT_POSTGRES_USER}" "${INIT_POSTGRES_DBNAME}"
fi
database_init_file="/initdb/${INIT_POSTGRES_DBNAME}.sql"
if [[ -f "${database_init_file}" ]]; then
    printf "\e[1;32m%-6s\e[m\n" "Initialize Database using sql file ..."
    psql \
        --dbname "${INIT_POSTGRES_DBNAME}" \
        --echo-all \
        --file "${database_init_file}"
fi
database_init_script="/initdb/${INIT_POSTGRES_DBNAME}.sh"
if [[ -f "${database_init_script}" ]]; then
    printf "\e[1;32m%-6s\e[m\n" "Initialize Database using script..."
    (. "${database_init_script}")
fi
if [[ -n "${INIT_IMMICH}" ]]; then
    printf "\e[1;32m%-6s\e[m\n" "Initialize Immich DB..."
    (. ./immich.sh)
fi
printf "\e[1;32m%-6s\e[m\n" "Update User Privileges on Database ..."
psql --command "grant all privileges on database \"${INIT_POSTGRES_DBNAME}\" to \"${INIT_POSTGRES_USER}\";"
