#!/usr/bin/env bash
set -euo pipefail

: "${CORE_DB:?CORE_DB is required}"
: "${STUDY_DB:?STUDY_DB is required}"
: "${CORE_DB_USER:?CORE_DB_USER is required}"
: "${CORE_DB_PASSWORD:?CORE_DB_PASSWORD is required}"
: "${STUDY_DB_USER:?STUDY_DB_USER is required}"
: "${STUDY_DB_PASSWORD:?STUDY_DB_PASSWORD is required}"

psql -v ON_ERROR_STOP=1 --username "postgres" --dbname "postgres" <<-EOSQL
  -- 1) Roles/users (idempotent)
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

  -- 2) Databases (idempotent) - cannot be inside DO block
  SELECT format('CREATE DATABASE %I OWNER %I', '${CORE_DB}', '${CORE_DB_USER}')
  WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = '${CORE_DB}') \gexec

  SELECT format('CREATE DATABASE %I OWNER %I', '${STUDY_DB}', '${STUDY_DB_USER}')
  WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = '${STUDY_DB}') \gexec

  -- 3) Ensure connect privileges (safe even if already granted)
  GRANT CONNECT ON DATABASE ${CORE_DB} TO ${CORE_DB_USER};
  GRANT CONNECT ON DATABASE ${STUDY_DB} TO ${STUDY_DB_USER};
EOSQL