#!/usr/bin/env bash
set -euo pipefail

: "${CORE_DB:?CORE_DB is required}"
: "${STUDY_DB:?STUDY_DB is required}"
: "${CORE_DB_USER:?CORE_DB_USER is required}"
: "${STUDY_DB_USER:?STUDY_DB_USER is required}"

# Allow users to connect to their databases
psql -v ON_ERROR_STOP=1 --username "postgres" --dbname "postgres" <<-EOSQL
  GRANT CONNECT ON DATABASE ${CORE_DB} TO ${CORE_DB_USER};
  GRANT CONNECT ON DATABASE ${STUDY_DB} TO ${STUDY_DB_USER};
EOSQL

# Grants inside core_db
psql -v ON_ERROR_STOP=1 --username "postgres" --dbname "${CORE_DB}" <<-EOSQL
  GRANT USAGE, CREATE ON SCHEMA public TO ${CORE_DB_USER};

  -- EF Core migrations create tables/sequences;
  ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${CORE_DB_USER};

  ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO ${CORE_DB_USER};
EOSQL

# Grants inside study_db
psql -v ON_ERROR_STOP=1 --username "postgres" --dbname "${STUDY_DB}" <<-EOSQL
  GRANT USAGE, CREATE ON SCHEMA public TO ${STUDY_DB_USER};

  ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${STUDY_DB_USER};

  ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO ${STUDY_DB_USER};
EOSQL
