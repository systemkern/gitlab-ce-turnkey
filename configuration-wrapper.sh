#!/bin/bash

set -m

####################
# Protecting the configure script by doulbe checking the variables here

if [ "$POSTGRES_SERVICE_HOST_NAME" = "" ]; then
  echo "Missing POSTGRES_SERVICE_HOST_NAME. Default value is 'localhost'"
  exit 1
fi
if [ "$POSTGRES_USER" = "" ]; then
  echo "Missing POSTGRES_USER. Default value is 'gitlab-psql'"
  exit 1
fi
if [ "$GITLAB_ADMIN_TOKEN" = "" ]; then
  echo "Missing GITLAB_ADMIN_TOKEN."
  exit 1
fi
if [ "$GITLAB_SECRETS_DB_KEY_BASE" = "" ]; then
  echo "Missing GITLAB_SECRETS_DB_KEY_BASE."
  exit 1
fi
# Start the first script that comes with gitlab image in background, as it never ends, it waits for all child process sigterm,
# We can not run our script after checking it's exit status.

/assets/wrapper >/dev/null &

# Start the second script now
/configure.sh >/var/log/configure.log 2>&1

#Bring the first process to foreground
fg %1
