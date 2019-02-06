#!/bin/bash

if [[ -z $1 ]] ||
        [[ -z $2 ]] ||
        [[ -z $3 ]] ||
	[[ -z $4 ]]; then
        echo "Missing required parameter for ethernet adapter, logstash IP, or servername"
        echo "Correct command usage: sudo bash deploy_metricbeat.sh <type of file beat> <nic adapter> <elasticsearch ip> <name of this server>"
        exit 0
fi

ip=$(ifconfig | grep -A 1 $2 | tail -n 1 | cut -d ':' -f 2 | awk '{print $1}')

if [[ -z $ip ]]; then
	"Server's LAN IP doesn't exist, please run ifconfig to diagnose"
	exit 0
fi

function remove_old_container() {
	sudo docker rm -f $1
	sudo rm docker-compose.yml
}I

function create_docker_compose() {
	sudo cp docker-compose.yml.template docker-compose.yml

	if [[ $1 == metricbeat ]]; then
		sudo sed -i -e "s/configyml/$1.yml/g" ./docker-compose.yml
	fi

	sudo sed -i -e "s/elasticip/$3/g" ./docker-compose.yml
	sudo sed -i -e "s/privateip/$ip/g" ./docker-compose.yml
	sudo sed -i -e "s/servername/$4/g" ./docker-compose.yml
}

function start_beat_container() {
	sudo docker-compose -f ./docker-compose.yml up -d
}

echo $1 $2 $3 $4
remove_old_container
create_docker_compose $1 $2 $3 $4
start_beat_container
