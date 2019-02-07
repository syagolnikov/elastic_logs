#!/bin/bash

PUBLIC_IP=$(curl icanhazip.com)
SYSTEM_OS=$(uname -a)
SERVER_PUBLIC_IP=$(curl icanhazip.com)

if [[ -z $1 ]] ||
        [[ -z $2 ]] ||
	[[ -z $3 ]] ||
        [[ -z $4 ]]; then
        echo "Missing required parameter for ethernet adapter, logstash IP, or servername"
        echo "Correct command usage: sudo bash deploy_metricbeat.sh <METRIC_BEAT_VERSION> <THIS_SERVERS_ETHERNET_ADAPTER> <ELASTICSEARCH_IP> <THIS_SERVERS_UNIQUE_NAME>"
        exit 0
fi

if [[ "$SYSTEM_OS" == *"Darwin"* ]]; then
    IP=$(ifconfig | grep broadcast | cut -d ' ' -f 2)
fi

if [[ "$SYSTEM_OS" == *"Ubuntu"* ]] || [[ "$SYSTEM_OS" == *"Linux"* ]] ; then
    IP=$(ifconfig | grep $2 -A 1 | tail -n 1 | cut -d ':' -f 2 | awk '{print $1}')
fi

if [[ -z $IP ]]; then
	"Server's LAN IP doesn't exist, please run ifconfig to diagnose"
	exit 0
fi

function remove_old_container() {
	sudo docker rm -f metricbeat
	sudo rm docker-compose.yml
}

function create_docker_compose() {
	sudo cp docker-compose.yml.template docker-compose.yml
  sudo sed -i -e "s/METRICBEAT_VERSION/$1/g" ./docker-compose.yml
  sudo sed -i -e "s/SERVER_PRIVATE_IP/$IP/g" ./docker-compose.yml
	sudo sed -i -e "s/ELASTICSEARCH_IP/$3/g" ./docker-compose.yml
	sudo sed -i -e "s/SERVER_NAME/$4/g" ./docker-compose.yml
  sudo sed -i -e "s/SERVER_PUBLIC_IP/$SERVER_PUBLIC_IP/g" ./docker-compose.yml
}

function start_beat_container() {
	sudo docker-compose -f ./docker-compose.yml up -d
}

remove_old_container
create_docker_compose $1 $2 $3 $4
start_beat_container
