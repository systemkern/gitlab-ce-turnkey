#!/usr/bin/env sh

if [ "$POSTGRES_SERVICE_HOST_NAME" = "" ]; then
  echo "Missing POSTGRES_SERVICE_HOST_NAME. Default value is 'localhost'"
  exit 1
fi
if [ "$POSTGRES_USER" = "" ]; then
  echo "Missing POSTGRES_USER. Default value is 'gitlab-psql'"
  exit 1
fi

echo "#_preconfig: Starting Database configuration Script"
echo "#_preconfig: Step 1 - Waiting for postgres to boot."

while ! pg_isready -U $POSTGRES_USER -h $POSTGRES_SERVICE_HOST_NAME >/dev/null 2>/dev/null; do
  echo ""
  echo "#_preconfig: Waiting until postgres is ready..."
  pg_isready -U $POSTGRES_USER -h $POSTGRES_SERVICE_HOST_NAME
  sleep 5
done
echo "#_preconfig: Postgresql is ready! :)"

echo "#_preconfig: Creating a database and a user for Gitlab..."

PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d $DB_NAME -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 || PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -h $POSTGRES_SERVICE_HOST_NAME -d $DB_NAME -c "CREATE DATABASE $DB_NAME ENCODING = 'UTF8' TABLESPACE = pg_default;"
PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d $DB_NAME -tc "CREATE EXTENSION IF NOT EXISTS pg_trgm ;"
PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d $DB_NAME -tc "SELECT 1 FROM pg_user WHERE usename = '$DB_USER'" | grep -q 1 || PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d $DB_NAME -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';"
PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d $DB_NAME -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d $DB_NAME -c "ALTER USER $DB_USER CREATEDB;"


echo "#_preconfig: Step 2 - Waiting for gitlab structure to be created."

VAR="t"
# The "t" and "f" - are results of PostgresSQL function "exists()". See using above. So if the the table exists in the database the function returns "t". If doesn't then "f"
while [ $VAR != "t" ]; do
  sleep 5
  VAR=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d $DB_NAME -tc "SELECT exists(SELECT table_name FROM information_schema.tables where table_name='personal_access_tokens')" | cut -d \| -f 1)
  echo "#_preconfig: Waiting for table personal_access_tokens: $VAR"
  VAR="t"
done


VAR=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d $DB_NAME -tc "SELECT exists(SELECT table_name FROM information_schema.tables where table_name='users')")
echo "#_preconfig: Waiting for table 'users'."

while [ $VAR != "t" ]; do
  echo "#_preconfig: Waiting for table 'users'."
  sleep 5
  VAR=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d $DB_NAME -tc "SELECT exists(SELECT table_name FROM information_schema.tables where table_name='users')")
done



VAR=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d $DB_NAME -tc "SELECT exists(SELECT id FROM public.users where id=1)")
  echo "#_preconfig: Waiting for gitlab root user to be created."

while [ $VAR != "t" ]; do
  echo "#_preconfig: Waiting for gitlab root user to be created."
  sleep 5
  VAR=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d $DB_NAME -tc "SELECT exists(SELECT id FROM public.users where id=1)")
done

echo "#_preconfig: Step 3 - create entities"

echo "#_preconfig: Gitlab structure is created. Waiting 15 sec for it to be completed..."

sleep 15

VAR=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_SERVICE_HOST_NAME -U $POSTGRES_USER -d $DB_NAME -tc "SELECT exists(SELECT id FROM public.personal_access_tokens where \"name\"='admin-api-token')")

if [ "$VAR" = " f" ]; then

  echo No Admin token found...will be created

  salt=$(echo $GITLAB_SECRETS_DB_KEY_BASE | cut -c1-32)
  token=$GITLAB_ADMIN_TOKEN$salt
  token_digest=$(echo $token | openssl sha256 -binary | base64 -)
  echo Created new token_digest: $token_digest

  sql_truncate="TRUNCATE TABLE public.personal_access_tokens;"
  sql_insert="INSERT INTO public.personal_access_tokens (id,user_id,\"name\",revoked,expires_at,created_at,updated_at,scopes,impersonation,token_digest) VALUES (1,1,'admin-api-token',false,NULL,'2019-12-10','2019-12-10','---
    - api
    - read_user
    - read_repository
    - write_repository
    - sudo',false,'FQuUQXUpDuWJgNyTZLXw8ev7y1O66MbaoaF5JuQmr7w=');"

  sql_update="UPDATE public.personal_access_tokens SET token_digest='$token_digest' WHERE id=1;"
  sql_select="SELECT id,user_id,\"name\",created_at,impersonation,token_digest FROM public.personal_access_tokens;"

  echo "#_preconfig: ############################################"

  echo "#_preconfig: Updating token Next lines MUST have \"UPDATE 1\" otherwise there was an error\n"

  PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -h $POSTGRES_SERVICE_HOST_NAME -d $DB_NAME -c "$sql_truncate"
  PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -h $POSTGRES_SERVICE_HOST_NAME -d $DB_NAME -c "$sql_insert"
  PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -h $POSTGRES_SERVICE_HOST_NAME -d $DB_NAME -c "$sql_update"
  exit_value=$?
  PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -h $POSTGRES_SERVICE_HOST_NAME -d $DB_NAME -c "$sql_select"

  if [ $exit_value -ne 0 ]; then
    echo "#_preconfig: ERROR SQL UPDATE was not successfull $exit_value"
  else
    echo "#_preconfig: SUCCESS"
  fi
fi

echo "#_preconfig: Script finished"
