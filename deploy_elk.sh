#!/bin/bash

# get IP address from mac or linux OS
SYSTEM_OS=$(uname -a)

if [[ "$SYSTEM_OS" == *"Darwin"* ]]; then
    IP=$(ifconfig | grep broadcast | cut -d ' ' -f 2)
fi

if [[ "$SYSTEM_OS" == *"Ubuntu"* ]] || [[ "$SYSTEM_OS" == *"Linux"* ]] ; then
    IP=$(ifconfig | grep eth0 -A 1 | tail -n 1 | cut -d ':' -f 2 | awk '{print $1}')
fi

if [[ -z $1 ]] ||
    [[ -z $2 ]] ||
    [[ -z $3 ]] ||
    [[ -z $4 ]] ||
    [[ -z $5 ]] ||
    [[ -z $6 ]]; then
        echo "Missing required parameters"
        echo "Correct command usage: sudo bash deploy_elk.sh <ELK_VERSION> <ES_MEMORY> <ES_PORTS> <LOGSTASH_MEMORY> <LOGSTASH_PORTS> <KIBANA_PORTS>"
				echo "Sample: sudo bash deploy_elk.sh 6.5.4 1g 9200:9200 512m 5044:5044 5601:5601"
				exit 0
fi

function remove_old_container() {
	sudo docker rm -f elastic_logs_logstash_1
  sudo docker rm -f elastic_logs_kibana_1
  sudo docker rm -f elastic_logs_elasticsearch_1
	sudo docker rmi elastic_logs_logstash
  sudo docker rmi elastic_logs_elasticsearch
  sudo docker rmi elastic_logs_kibana
}

validate_param_variables() {

	if [[ $1 =~ ^[0-9.]+$ ]]; then
					echo "ELK_VERSION validated"
	else
					echo "ELK_VERSION is not correctly formatted or may not exist"
					exit 0
	fi

	if [[ $2 =~ ^[0-9mg]+$ ]]; then
					echo "ES_MEM validated"
	else
					echo "ES_MEM is not correctly formatted or may not exist"
					exit 0
	fi

	if [[ $3 =~ ^[0-9:]+$ ]]; then
					echo "ES_PORT validated"
	else
					echo "ES_PORT is not correctly formatted or may not exist"
					exit 0
	fi

	if [[ $4 =~ ^[0-9mg]+$ ]]; then
					echo "LOGSTASH_MEM validated"
	else
					echo "LOGSTASH_MEM is not correctly formatted or may not exist"
					exit 0
	fi

	if [[ $5 =~ ^[0-9:]+$ ]]; then
					echo "LOGSTASH_PORT validated"
	else
					echo "LOGSTASH_PORT is not correctly formatted or may not exist"
					exit 0
	fi

	if [[ $6 =~ ^[0-9:]+$ ]]; then
					echo "KIBANA_PORT validated"
	else
					echo "KIBANA_PORT is not correctly formatted or may not exist"
					exit 0
	fi
}

function create_docker_compose() {
	echo "ELK_VERSION=$1" | sudo tee ./.env
	echo "ES_MEM=$2" | sudo tee -a ./.env
	echo "ES_PORT=$3" | sudo tee -a ./.env
	echo "LOGSTASH_MEM=$4" | sudo tee -a ./.env
	echo "LOGSTASH_PORT=$5" | sudo tee -a ./.env
	echo "KIBANA_PORT=$6" | sudo tee -a ./.env
}

function start_elk_containers (){
	echo "Deploying ELK stack"
	sudo docker-compose build ### build images from latest
	sudo docker-compose up -d ### STARTS the ELK stac

  #wait for elk to load
	sleep 30

	#fix for geoip bug
	curl -XPUT http://$IP:9200/_template/filebeat -H 'Content-type:application/json' -d @./elasticsearch/templates/template.json
	#download/upload dashboard and index objects
	#sleep 30
	#curl -XGET localhost:5601/api/kibana/dashboards/export?dashboard=64e74580-1561-11e9-ad62-b53ba47cdc61
	#curl -XPOST localhost:5601/api/kibana/dashboards/import -H 'kbn-xsrf:true' -H 'Content-type:application/json' -d @./objects/syslog_ui.json
}

  remove_old_container
	validate_param_variables $1 $2 $3 $4 $5 $6
	create_docker_compose $1 $2 $3 $4 $5 $6
	start_elk_containers
