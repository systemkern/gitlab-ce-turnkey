#!/usr/bin/env sh

POSTGRES_USER="gitlab-psql"
POSTGRES_SERVICE_HOST_NAME="localhost"
POSTGRES_PASSWORD=""
GITLAB_DB_NAME="gitlabhq_production"

echo Starting;

echo "############################################"

while ! pg_isready -U $POSTGRES_USER -h $POSTGRES_SERVICE_HOST_NAME > /dev/null 2> /dev/null; do
    echo Waiting for postgres is ready...
    sleep 5
done;

echo "############################################"

echo Reading env variables
[ -z "$DB_NAME" ] && DB_NAME="db_"$(date +%d%m%Y_%H%M%S)
[ -z "$DB_USER" ] && DB_USER="default_user"
[ -z "$DB_PASS" ] && DB_PASS="default_pass"


echo "############################################"
echo Creating a database and a user for Gitlab...

PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 || PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -h $POSTGRES_SERVICE_HOST_NAME -d postgres -c "CREATE DATABASE $DB_NAME ENCODING = 'UTF8' TABLESPACE = pg_default;";

PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d $DB_NAME -tc "CREATE EXTENSION IF NOT EXISTS pg_trgm ;";

PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d postgres -tc "SELECT 1 FROM pg_user WHERE usename = '$DB_USER'" | grep -q 1 || PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d postgres -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';";

PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;";
PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d postgres -c "ALTER USER $DB_USER CREATEDB;";

echo "############################################"

VAR=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $DB_USER -d $DB_NAME -tc "SELECT exists(SELECT datname FROM pg_database WHERE datname = '$GITLAB_DB_NAME')");

# The "t" and "f" - are results of PostgresSQL function "exists()". See using above. So if the the database exists in the server, the function returns "t". If doesn't then "f"
while [ $VAR != "t" ]; do
    echo Waiting for gitlab structure is created. Current value $VAR;
    sleep 30;
    VAR=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $DB_USER -d $DB_NAME -tc "SELECT exists(SELECT datname FROM pg_database WHERE datname = '$GITLAB_DB_NAME')");
done;

echo "############################################"

VAR=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d $GITLAB_DB_NAME -tc "SELECT exists(SELECT table_name FROM information_schema.tables where table_name='personal_access_tokens')");

# The "t" and "f" - are results of PostgresSQL function "exists()". See using above. So if the the table exists in the database the function returns "t". If doesn't then "f"
while [ $VAR != "t" ]; do
    echo Waiting for gitlab structure is created. Current value $VAR;
    sleep 30;
    VAR=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d $GITLAB_DB_NAME -tc "SELECT exists(SELECT table_name FROM information_schema.tables where table_name='personal_access_tokens')");
done;

echo "############################################"

VAR=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d $GITLAB_DB_NAME -tc "SELECT exists(SELECT table_name FROM information_schema.tables where table_name='users')");

while [ $VAR != "t" ]; do
    echo Waiting for gitlab structure is created. Current value $VAR;
    sleep 30;
    VAR=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d $GITLAB_DB_NAME -tc "SELECT exists(SELECT table_name FROM information_schema.tables where table_name='users')");
done;

echo "############################################"

