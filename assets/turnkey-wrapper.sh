#!/bin/bash
set -m


### The script exports environment variables created from ENV of Dockerfile.
### These needs to be part of wrapper as if at run time any base ENV is replaced by -e ,
###   it does not change other ENV variables created from them
### This script gets copied to /etc/bash.bashrc to set env after docker run


### Gitlab dynamic variables created from ENV mentioned in Dockerfile
export GITLAB_ROOT_URL=${GITLAB_ROOT_URL:-"http://$INSTANCE_HOST"}

export GITLAB_OMNIBUS_CONFIG="\
    external_url '$GITLAB_ROOT_URL';                                \
    nginx['redirect_http_to_https'] = false;                        \
    "

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

  CONTAINER_IP=$(hostname -I | awk '{print $1}')
  echo "Container IP is: $CONTAINER_IP"

  echo "### Configuring gitlab runner for $INSTANCE_HOST:$GITLAB_PORT"
  gitlab-runner register --non-interactive  \
    --url="http://localhost:80/"            \
    --docker-network-mode bridge            \
    --registration-token "$TOKEN"           \
    --executor "docker"                     \
    --docker-image alpine:latest            \
    --docker-volumes /var/run/docker.sock:/var/run/docker.sock \
    --description "Turnkey packaged Runner" \
    --run-untagged="true"                   \
    --locked="false"                        \
    --access-level="not_protected"          \
    --docker-extra-hosts "$INSTANCE_HOST:$CONTAINER_IP"

  gitlab-runner start
} >/var/log/configuration.log

rm -f /var/log/configuration.lock

pip3 install -r /assets/test/requirements.txt
python3 /assets/test/test-login.py

#Bring the first process to foreground
fg %1
