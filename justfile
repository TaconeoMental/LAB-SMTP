# Use with https://github.com/casey/just :)
set dotenv-load

# Build Docker image
build:
  echo "Building Docker image"
  docker build --tag $MAINTAINER/$PROJECT:$VERSION .

# Start local lab
start SUBNET: #build
  #!/usr/bin/env bash
  CIDR_REGEX="(((25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?))(\/([8-9]|[1-2][0-9]|3[0-2]))([^0-9.]|$)"
  if [[ ! "{{SUBNET}}" =~ $CIDR_REGEX ]]; then echo "{{SUBNET}} is not a valid CIDR range"; fi
  docker compose --file ./docker-compose.yml up --detach --force-recreate

# Stop local lab
stop:
  docker compose --file ./docker-compose.yml stop

# Delete Docker image and container
purge:
  docker image rm $MAINTAINER/$PROJECT:$VERSION
  docker rm --force $CONTAINER_NAME
