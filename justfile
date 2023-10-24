# Use with https://github.com/casey/just :)
set dotenv-load

config_dir := justfile_directory() + "/config"
bin_dir := justfile_directory() + "/bin"
volumes_dir := justfile_directory() + "/volumes"

# Build Docker image
build: && create-config
  echo $(id)
  echo "Building Docker image"
  docker build --tag $MAINTAINER/$PROJECT:$VERSION ./docker

# Create zone files
create-config:
  echo "Creating zone files and BIND9 configuration"
  {{bin_dir}}/create_zones.py --config-dir {{config_dir}}/records --output-dir {{volumes_dir}}/bind/etc

# Start local lab
start: build
  #!/usr/bin/env bash
  network=$(cat {{config_dir}}/network.yml | yq '.network')
  gateway=$(cat {{config_dir}}/network.yml | yq '.gateway')
  export ADDR_DNS_SERVER=$(cat {{config_dir}}/network.yml | yq -r '.nameserver')

  docker network create --gateway $gateway --subnet $network $DOCKER_NETWORK_NAME
  docker compose --file ./docker-compose.yml up --detach --force-recreate

# Stop local lab
stop:
  docker compose --file ./docker-compose.yml stop

# Delete Docker image and container
purge:
  -docker image rm $MAINTAINER/$PROJECT:$VERSION
  -docker rm --force $BIND9_CONTAINER_NAME
  -docker network rm $DOCKER_NETWORK_NAME
  -rm {{volumes_dir}}/bind/etc/{db.*,named.conf.zones}
