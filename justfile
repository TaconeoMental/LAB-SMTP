# Use with https://github.com/casey/just :)

_default:
    @just --list --unsorted

set dotenv-load

HERE   := justfile_directory()
CONFIG := HERE / "config"
BIN    := HERE / "bin"
VOLS   := HERE / "volumes"

NETWORK_CONF := CONFIG / "lab.yml"
COMPOSE_FILE := HERE / "docker-compose.yml"
ENV_FILE     := HERE / ".env"

DOCKER_COMPOSE := "docker compose --file " + COMPOSE_FILE

# Build Docker image
build: && create-config
  echo "Building Docker image"
  docker build --tag $MAINTAINER/$PROJECT:$VERSION {{HERE}}/docker

# Create zone files and container network
create-config: stop
  #!/usr/bin/env bash
  set -euo pipefail

  echo "Creating zone files and BIND9 configuration"
  {{BIN}}/create_zones.py --config-dir {{CONFIG}}/records --output-dir {{VOLS}}/bind/etc

  echo "Creating network"
  {{BIN}}/create_network.sh --config-file {{NETWORK_CONF}} --network-name $DOCKER_NETWORK_NAME

# Start local lab
start: build
  {{BIN}}/lab_run.sh \
    --action start \
    --compose-file {{COMPOSE_FILE}} \
    --config-file {{NETWORK_CONF}}

# Stop local lab
stop:
  {{BIN}}/lab_run.sh \
    --action stop \
    --compose-file {{COMPOSE_FILE}} \
    --config-file {{NETWORK_CONF}}

# Delete current instance
delete:
  -docker rm --force $BIND9_CONTAINER_NAME
  -docker network rm $DOCKER_NETWORK_NAME
  -rm {{VOLS}}/bind/etc/{db.*,named.conf.zones}

# Delete Docker image and container
purge: && delete
  -docker image rm $MAINTAINER/$PROJECT:$VERSION
