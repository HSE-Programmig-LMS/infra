#!/usr/bin/env bash
set -euo pipefail

# Fail-fast if env vars are missing
: "${CORE_DB:?CORE_DB is required}"
: "${STUDY_DB:?STUDY_DB is required}"
: "${CORE_DB_USER:?CORE_DB_USER is required}"
: "${CORE_DB_PASSWORD:?CORE_DB_PASSWORD is required}"
: "${STUDY_DB_USER:?STUDY_DB_USER is required}"
: "${STUDY_DB_PASSWORD:?STUDY_DB_PASSWORD is required}"

psql -v ON_ERROR_STOP=1 --username "postgres" --dbname "postgres" <<-EOSQL
  -- Databases
  CREATE DATABASE ${CORE_DB};
  CREATE DATABASE ${STUDY_DB};

  -- Roles/users (idempotent)
  DO \$\$
  BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${CORE_DB_USER}') THEN
      CREATE ROLE ${CORE_DB_USER} LOGIN PASSWORD '${CORE_DB_PASSWORD}';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${STUDY_DB_USER}') THEN
      CREATE ROLE ${STUDY_DB_USER} LOGIN PASSWORD '${STUDY_DB_PASSWORD}';
    END IF;
  END
  \$\$;
EOSQL
