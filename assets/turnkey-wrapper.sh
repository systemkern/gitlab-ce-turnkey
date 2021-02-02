#!/bin/bash
########################################
set -u # error on usage of undefined variables
########################################
echo "GITLAB_ROOT_URL: $GITLAB_ROOT_URL"

export GITLAB_PROTOCOL="$(echo "$GITLAB_ROOT_URL" | grep :// | sed -e's,^\(.*://\).*,\1,g')"
export GITLAB_NOPROTO_URL="$(echo ${GITLAB_ROOT_URL/"$GITLAB_PROTOCOL"/})"
export RM_USER="$(echo "$GITLAB_NOPROTO_URL" | grep @ | cut -d@ -f1)"
export GITLAB_HOSTPORT="$(echo ${GITLAB_NOPROTO_URL/"$RM_USER"@/} | cut -d/ -f1)"
export GITLAB_HOST="$(echo "$GITLAB_HOSTPORT" | sed -e 's,:.*,,g')"
export GITLAB_PORT="$(echo "$GITLAB_HOSTPORT" | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"

echo "GITLAB_PROTOCOL:$GITLAB_PROTOCOL"
echo "GITLAB_HOST:$GITLAB_HOST"
echo "GITLAB_PORT:$GITLAB_PORT"


### Gitlab dynamic variables created from ENV mentioned in Dockerfile
export DOCKER_REGISTRY_PORT=${DOCKER_REGISTRY_PORT:-5050}
export GITLAB_ROOT_URL=${GITLAB_ROOT_URL:-"http://$GITLAB_HOSTPORT"}
export DOCKER_REGISTRY="$GITLAB_HOST:${DOCKER_REGISTRY_PORT}"
export DOCKER_REGISTRY_EXTERNAL_URL="http://${DOCKER_REGISTRY}"

export GITLAB_OMNIBUS_CONFIG="\
    external_url '$GITLAB_ROOT_URL';                                \
    nginx['redirect_http_to_https'] = false;                        \
    registry_external_url '$DOCKER_REGISTRY_EXTERNAL_URL';          \
    registry_nginx['enable'] = true;                                \
    registry_nginx['listen_port'] = $DOCKER_REGISTRY_PORT;          \
    redis['bind'] = '127.0.0.1';                                    \
    redis['port'] = 6379;                                           \
    "

echo "##########################################"
echo "$GITLAB_OMNIBUS_CONFIG"
echo "##########################################"

# Start the first script that comes with gitlab image in background,
# it never ends, therefore we put it in the background with the '&'
/assets/gitlab-wrapper >/dev/null &

# Wait for Gitlab to enable the database
touch /var/log/configuration.lock
touch /var/log/configuration.log
{
  echo "### $(date) Waiting for Gitlab Runners API. The runners API is running in a separate process from the normal API"
  until [ "$(curl --silent --output /dev/null -w ''%{http_code}'' "localhost:$GITLAB_PORT/runners")" = "302" ]; do
    printf '.'
    sleep 5;
  done
  echo "### $(date) Expecting code 302; received: $(curl --silent --output /dev/null -w ''%{http_code}'' "localhost:$GITLAB_PORT/runners")"

  echo "### Getting Gitlab runners registration token from Gitlab."
  TOKEN=$(gitlab-rails runner -e production "puts Gitlab::CurrentSettings.current_application_settings.runners_registration_token" | tr -d '\r')
  echo TOKEN="$TOKEN"

  CONTAINER_IP=$(hostname -I | awk '{print $1}')
  echo "Container IP is: $CONTAINER_IP"

  echo "### Configuring gitlab runner for $GITLAB_HOSTPORT"
  gitlab-runner register --non-interactive  \
    --url="http://localhost:$GITLAB_PORT/"  \
    --docker-network-mode bridge            \
    --registration-token "$TOKEN"           \
    --executor "docker"                     \
    --docker-image alpine:latest            \
    --docker-volumes /var/run/docker.sock:/var/run/docker.sock \
    --description "Turnkey packaged Runner" \
    --run-untagged="true"                   \
    --locked="false"                        \
    --access-level="not_protected"          \
    --docker-extra-hosts "$GITLAB_HOST:$CONTAINER_IP"

  gitlab-runner start
} >/var/log/configuration.log

rm -f /var/log/configuration.lock

# Tail all logs
gitlab-ctl tail &

# Wait for SIGTERM
wait
