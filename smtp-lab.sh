#!/bin/bash

#set -o errexit   # abort on nonzero exitstatus
#set -o nounset   # abort on unbound variable
#set -o pipefail  # don't hide errors within pipes

DOCKERCOMPOSE="docker compose --file docker-compose.yml"

# Helper
addr_from_subnet() {
    LAST_OCTET="$2"
    OCTETS=$(echo $DOCKER_NET_SUBNET | awk '{split($0,ip,"/"); print ip[1]}' | cut -d "." -f 1,2,3)
    printf "$OCTETS.%s" $LAST_OCTET;
}

export DOCKER_NET_NAME="smtp_lab_network"
export DOCKER_NET_SUBNET="172.22.0.0/16"
export DOCKER_NET_GATEWAY=$(addr_from_subnet $DOCKER_NET_SUBNET 1)

create_network() {
    docker network create --gateway $DOCKER_NET_GATEWAY --subnet $DOCKER_NET_SUBNET $DOCKER_NET_NAME
}


export ADDR_DNS_SERVER=$(addr_from_subnet $DOCKER_NET_SUBNET 2)
export ADDR_MX_SERVER_1=$(addr_from_subnet $DOCKER_NET_SUBNET 10)
export ADDR_MX_SERVER_2=$(addr_from_subnet $DOCKER_NET_SUBNET 11)
export ADDR_MX_SERVER_3=$(addr_from_subnet $DOCKER_NET_SUBNET 12)


function lab_init() {
    create_network
    echo "[+] Created lab network: $DOCKER_NET_SUBNET"
    $DOCKERCOMPOSE up -d
    docker exec lab_mailserver setup email add admin@permissive.accela.wired admin.smtp
    echo "Lab is now running with DNS @ $ADDR_DNS_SERVER"
}

function lab_start() {
    $DOCKERCOMPOSE start
    echo "Lab is now running :)"
}

function lab_stop() {
    $DOCKERCOMPOSE stop
}

function lab_down() {
    $DOCKERCOMPOSE down
    docker network rm $DOCKER_NET_NAME
}

function lab_help() {
    echo "$0 [ init | start | stop | down ]"
}

if [ $# -eq 0 ]; then
  lab_help
  exit 1
fi

case $1 in
  "init")
    lab_init
    ;;
  "start")
    lab_start
    ;;
  "stop")
    lab_stop
    ;;
  "down")
    lab_down
    ;;
  *)
    $DOCKERCOMPOSE $@
    ;;
esac

exit 0
