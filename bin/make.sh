#!/bin/sh
#
#
#
# Fail on any error
set -e

### Substituting for Gilab's CI environment variables
if [ "$CI_COMMIT_REF_SLUG" = "" ]; then
  CI_COMMIT_REF_SLUG="nightly"
  echo "Missing CI_COMMIT_REF_SLUG. Using Default value is '$CI_COMMIT_REF_SLUG'"
fi
if [ "$CI_REGISTRY_IMAGE" = "" ]; then
  shopt -s extglob    # enable +(...) glob syntax
  result=${PWD%%+(/)} # trim however many trailing slashes exist
  CI_REGISTRY_IMAGE=${result##*/}
  echo "Missing CI_REGISTRY_IMAGE. Using '$CI_REGISTRY_IMAGE'"
fi

parse() {
  export TAG="${CI_COMMIT_REF_SLUG}"
  if [ $TAG = "master" ]; then TAG="latest"; fi
  export IMAGE_PATH="$CI_REGISTRY_IMAGE:$TAG"
  echo "Fully qualified docker image name is '$IMAGE_PATH'"
}

# Parse flags
while [ -n "$1" ]; do
  case "$1" in
  -p | --parse)
    echo "Parsing $CI_COMMIT_REF_SLUG"
    prepare
    exit 0
    ;;
  *) echo "Option $1 not recognized" ;;
  esac
  shift
done

if [ "$IMAGE_PATH" = "" ]; then
  echo "Missing IMAGE_PATH. parsing environment variables"
  parse
fi

docker build --tag "$IMAGE_PATH" .
