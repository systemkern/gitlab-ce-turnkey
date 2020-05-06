#!/bin/bash
set -m

# Start the first script that comes with gitlab image in background, as it never ends, it waits for all child process sigterm,
# We can not run our script after checking it's exit status.

/assets/wrapper >/dev/null &

# Wait for Gitlab to enable the database

touch /var/log/configuration.lock
touch /var/log/configuration.log
{
  echo "### $(date) Waiting for Gitlab Runners API. The runners API is running in a separate process from the normal API"
  until [ "$(curl --silent --output /dev/null -w ''%{http_code}'' localhost:80/runners)" = "302" ]; do
    printf '.'
    sleep 5;
  done
  echo "### $(date) Expecting code 302; received: $(curl --silent --output /dev/null -w ''%{http_code}'' localhost:80/runners)"

  echo "### Getting Gitlab runners registration token from Gitlab."
  TOKEN=$(gitlab-rails runner -e production "puts Gitlab::CurrentSettings.current_application_settings.runners_registration_token" | tr -d '\r')
  echo TOKEN="$TOKEN"

  echo "### Configuring gitlab runner for localhost:$GITLAB_PORT"

  gitlab-runner register --non-interactive \
    --url="http://localhost:80/" \
    --docker-network-mode docker-network \
    --registration-token "$TOKEN" \
    --executor "docker" \
    --docker-image alpine:latest \
    --docker-volumes /var/run/docker.sock:/var/run/docker.sock \
    --description "Packaged Runner" \
    --run-untagged="true" \
    --locked="false" \
    --access-level="not_protected"

  gitlab-runner start

} >/var/log/configuration.log
rm -f /var/log/configuration.lock

#Bring the first process to foreground
fg %1
