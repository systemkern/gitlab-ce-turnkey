#!/usr/bin/env sh

########################################
# Checking Input Parameters
########################################
if [ "$POSTGRES_SERVICE_HOST_NAME" = "" ]; then
  echo "gitlab-db-config $(date): Missing POSTGRES_SERVICE_HOST_NAME. Default value is 'localhost'"
  exit 1
fi
if [ "$POSTGRES_USER" = "" ]; then
  echo "gitlab-db-config $(date): Missing POSTGRES_USER. Default value is 'gitlab-psql'"
  exit 1
fi
if [ "$GITLAB_ADMIN_TOKEN" = "" ]; then
  echo "gitlab-db-config $(date): Missing GITLAB_ADMIN_TOKEN."
  exit 1
fi
if [ "$GITLAB_SECRETS_DB_KEY_BASE" = "" ]; then
  echo "gitlab-db-config $(date): Missing GITLAB_SECRETS_DB_KEY_BASE."
  exit 1
fi

#
#
########################################
# Waiting for Postgres startup
########################################
echo "gitlab-db-config $(date): Starting Database configuration Script"
echo "gitlab-db-config $(date): Step 1 - Waiting for postgres to boot."

while ! pg_isready -U $POSTGRES_USER -h $POSTGRES_SERVICE_HOST_NAME >/dev/null 2>/dev/null; do
  echo "gitlab-db-config $(date): Waiting until postgres is ready..."
  echo "gitlab-db-config $(date): $(pg_isready -U $POSTGRES_USER -h $POSTGRES_SERVICE_HOST_NAME)"
  sleep 5
done
echo "gitlab-db-config $(date): Postgresql is ready! :)"

#
#
########################################
# Ensuring access parameters
########################################
echo "gitlab-db-config $(date): Creating a database and database schema '$DB_NAME' and user '$DB_USER' for Gitlab as posgres"
PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" |
  grep -q 1 ||
  PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -h $POSTGRES_SERVICE_HOST_NAME -d postgres -c "CREATE DATABASE $DB_NAME ENCODING = 'UTF8' TABLESPACE = pg_default;"

PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d postgres -tc "CREATE EXTENSION IF NOT EXISTS pg_trgm ;"

PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d postgres -tc "SELECT 1 FROM pg_user WHERE usename = '$DB_USER'" |
  grep -q 1 ||
  PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d postgres -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';"

PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d postgres -c "ALTER USER $DB_USER CREATEDB;"

#
#
########################################
# Waiting for necessary database tables
########################################
VAR="f"
echo "gitlab-db-config $(date): Step 2 - Waiting for gitlab structure to be created."
# The "t" and "f" - are results of PostgresSQL function "exists()". See using above. So if the the table exists in the database the function returns "t". If doesn't then "f"
while [ $VAR != "t" ]; do
  sleep 5
  VAR=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d $DB_NAME -tc "SELECT exists(SELECT table_name FROM information_schema.tables where table_name='personal_access_tokens')")
  echo "gitlab-db-config $(date): Waiting for Gitlab's to create table 'personal_access_token': $VAR"
done
echo "gitlab-db-config $(date): Found table table 'personal_access_token': $VAR"

#
#
VAR="f"
while [ $VAR != "t" ]; do
  VAR=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d $DB_NAME -tc "SELECT exists(SELECT table_name FROM information_schema.tables where table_name='users')")
  echo "gitlab-db-config $(date): Waiting for Gitlab's to create table 'users': $VAR"
  sleep 5
done
echo "gitlab-db-config $(date): Found table table 'users': $VAR"

#
#
VAR="f"
while [ $VAR != "t" ]; do
  echo "gitlab-db-config $(date): Waiting for Gitlab's to create root user: $VAR"
  sleep 5
  VAR=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d $DB_NAME -tc "SELECT exists(SELECT id FROM public.users where id=1)")
done
echo "gitlab-db-config $(date): Found Gitlab's root user with id = 1: $VAR"

#
#
########################################
# Create custom database entries
########################################
echo "gitlab-db-config $(date): Gitlab structure is created. Waiting 15 sec for it to be completed..."
sleep 15
echo "gitlab-db-config $(date): Step 3 - create entities"

VAR="f"
VAR=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d $DB_NAME -tc "SELECT exists(SELECT id FROM public.personal_access_tokens where \"name\"='admin-api-token')")
if [ "$VAR" != "t" ]; then
  echo "gitlab-db-config $(date): No Admin token found...will be created"
  echo "gitlab-db-config $(date): Basing token on $GITLAB_ADMIN_TOKEN"

  # Do _NOT_ put quotes around these variables
  # It will change the handling by the parser and lead to wrong digest and thus unusable tokens
  SALT=$(echo $GITLAB_SECRETS_DB_KEY_BASE | cut -c1-32)
  TOKEN=$GITLAB_ADMIN_TOKEN$SALT
  TOKEN_DIGEST=$(echo $TOKEN | openssl sha256 -binary | base64 -)
  echo "gitlab-db-config $(date): Created new TOKEN_digest: $TOKEN_DIGEST"

  sql_truncate="TRUNCATE TABLE public.personal_access_tokens;"
  sql_insert="INSERT INTO public.personal_access_tokens (id,user_id,\"name\",revoked,expires_at,created_at,updated_at,scopes,impersonation,token_digest) VALUES (1,1,'admin-api-token',false,NULL,'2019-12-10','2019-12-10','---
    - api
    - read_user
    - read_repository
    - write_repository
    - sudo',false,'$TOKEN_DIGEST');"

  echo "gitlab-db-config $(date): ############################################"
  echo "gitlab-db-config $(date): Updating token Next lines MUST have \"UPDATE 1\" otherwise there was an error\n"

  PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -h "$POSTGRES_SERVICE_HOST_NAME" -d "$DB_NAME" -c "$sql_truncate"
  PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -h "$POSTGRES_SERVICE_HOST_NAME" -d "$DB_NAME" -c "$sql_insert"
  #sql_update="UPDATE public.personal_access_tokens SET token_digest='$TOKEN_DIGEST' WHERE id=1;"
  #PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -h "$POSTGRES_SERVICE_HOST_NAME" -d "$DB_NAME" -c "$sql_update"
  #exit_value=$?
  sql_select="SELECT id,user_id,\"name\",created_at,impersonation,token_digest FROM public.personal_access_tokens;"
  PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -h "$POSTGRES_SERVICE_HOST_NAME" -d "$DB_NAME" -c "$sql_select"

  #if [ $exit_value -ne 0 ]; then
  #  echo "gitlab-db-config $(date): ERROR SQL UPDATE was not successfull $exit_value"
  #else
  #  echo "gitlab-db-config $(date): SUCCESS"
  #fi
else
  echo "Found an Admin token in Gitlab's database with where name ='admin-api-token': $VAR"
fi

echo "gitlab-db-config $(date): Script finished"
