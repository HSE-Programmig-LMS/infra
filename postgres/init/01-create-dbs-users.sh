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
  -- Databases (idempotent)
  DO \$\$
  BEGIN
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '${CORE_DB}') THEN
      CREATE DATABASE ${CORE_DB};
    END IF;
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '${STUDY_DB}') THEN
      CREATE DATABASE ${STUDY_DB};
    END IF;
  END
  \$\$;

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

  -- Ownership / connect privileges
  ALTER DATABASE ${CORE_DB} OWNER TO ${CORE_DB_USER};
  ALTER DATABASE ${STUDY_DB} OWNER TO ${STUDY_DB_USER};

  GRANT CONNECT ON DATABASE ${CORE_DB} TO ${CORE_DB_USER};
  GRANT CONNECT ON DATABASE ${STUDY_DB} TO ${STUDY_DB_USER};
EOSQL