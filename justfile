# Use with https://github.com/casey/just :)

_default:
    @just --list --unsorted

set dotenv-load

CONFIG := "./config"
BIN    := "./bin"
VOLS   := "./volumes"
NETWORK_CONF := CONFIG / "network.conf.env"

COMPOSE := "docker compose --env-file " + NETWORK_CONF + " --file ./docker-compose.yml"

# Build Docker image
build: && create-config
  echo "Building Docker image"
  docker build --tag $MAINTAINER/$PROJECT:$VERSION ./docker

# Create zone files and container network
create-config: stop
  #!/usr/bin/env bash
  set -euo pipefail

  echo "Creating zone files and BIND9 configuration"
  {{BIN}}/create_zones.py --config-dir {{CONFIG}}/records --output-dir {{VOLS}}/bind/etc

  echo "Creating network"
  source {{NETWORK_CONF}}
  docker network rm --force $DOCKER_NETWORK_NAME
  docker network create --gateway $LAB_GATEWAY --subnet $LAB_NETWORK $DOCKER_NETWORK_NAME

# Start local lab
start: build
  {{COMPOSE}} up --detach --force-recreate

# Stop local lab
stop:
  {{COMPOSE}} stop

# Delete current instance
delete:
  -docker rm --force $BIND9_CONTAINER_NAME
  -docker network rm $DOCKER_NETWORK_NAME
  -rm {{VOLS}}/bind/etc/{db.*,named.conf.zones}

# Delete Docker image and container
purge: && delete
  -docker image rm $MAINTAINER/$PROJECT:$VERSION
