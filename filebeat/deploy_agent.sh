#!/bin/bash

#Hard coded variables to load into docker-compose.yml
DOCKER_LOG_PATH="\/var\/lib\/docker\/containers:\/var\/lib\/docker\/containers:ro"
DOCKER_SOCK_PATH="\/var\/run\/docker.sock:\/var\/run\/docker.sock:ro"
ETHERNET_ADAPTER=$1
FILEBEAT_CONFIG_PATH=".\/config\/filebeat.yml:\/usr\/share\/filebeat\/filebeat.yml:ro"
FILEBEAT_VERSION="6.5.4"
PUBLIC_IP=$(curl icanhazip.com)
SYSLOG_LOG_PATH="\/var\/log:\/syslog"

function check_variables() {
    if [[ -z $1 ]] ||
        [[ -z $2 ]] ||
        [[ -z $3 ]] ||
    	  [[ -z $4 ]] ||
        [[ -z $5 ]]; then
         echo "Missing required parameters"
         echo "Correct command usage: sudo bash deploy_agent.sh <THIS_SERVERS_ETHERNET_ADAPTER> <ELK_SERVICE> <ELK_IP> <ELK_PORT> <THIS_SERVERS_UNIQUE_NAME>"
         exit 0
    fi
}

function validate_variables() {
  PRIVATE_IP=$(ifconfig | grep -A 1 $ETHERNET_ADAPTER | tail -n 1 | cut -d ':' -f 2 | awk '{print $1}')
  ADAPTER_CHECK=$(ifconfig | grep $ETHERNET_ADAPTER)

  if [[ -z $ADAPTER_CHECK ]]; then
      echo "adapter specified doesn't exist on this server"
      exit 0
  fi

  if [[ $PRIVATE_IP =~ ^[0-9.]+$ ]]; then
      echo "Server ip valid"
  else
      echo "Server LAN IP is not correctly formatted or may not exist"
      exit 0
  fi

  if [[ $2 == "logstash" ]] || [[ $2 == "elasticsearch" ]]; then
  	  echo "ELK name valid"
  else
      echo "ELK name is not correct"
  	  exit 0
  fi

  if [[ $3 =~ ^[0-9.]+$ ]]; then
      echo "ELK IP valid"
  else
      echo "ELK IP address is not correctly formatted"
      exit 0
  fi

  if [[ $4 =~ ^[0-9]+$ ]]; then
      echo "ELK port valid"
  else
      echo "ELK port is not correctly formatted"
      exit 0
  fi

  if [[ $5 =~ ^[a-z]* ]]; then
      echo "This servers is name valid"
  else
      echo "This servers name has unrecognizable characters"
      exit 0
  fi
}

function remove_old_container() {
	sudo docker rm -f filebeat
	sudo rm docker-compose.yml
}

function create_docker_compose() {
  sudo cp docker-compose.yml.template docker-compose.yml
  sudo sed -i -e "s/SYSLOG_LOG_PATH/$SYSLOG_LOG_PATH/g" ./docker-compose.yml
  sudo sed -i -e "s/DOCKER_LOG_PATH/$DOCKER_LOG_PATH/g" ./docker-compose.yml
  sudo sed -i -e "s/DOCKER_SOCK_PATH/$DOCKER_SOCK_PATH/g" ./docker-compose.yml
  sudo sed -i -e "s/FILEBEAT_CONFIG_PATH/$FILEBEAT_CONFIG_PATH/g" ./docker-compose.yml

  sudo sed -i -e "s/FILEBEAT_VERSION/$FILEBEAT_VERSION/g" ./docker-compose.yml
  sudo sed -i -e "s/PUBLIC_IP/$PUBLIC_IP/g" ./docker-compose.yml
  sudo sed -i -e "s/PRIVATE_IP/$PRIVATE_IP/g" ./docker-compose.yml

  sudo sed -i -e "s/COLLECTOR_NAME/$2/g" ./docker-compose.yml
  sudo sed -i -e "s/COLLECTOR_IP/$3/g" ./docker-compose.yml
  sudo sed -i -e "s/COLLECTOR_PORT/$4/g" ./docker-compose.yml
  sudo sed -i -e "s/SERVER_NAME/$5/g" ./docker-compose.yml
}

function start_filebeat_container() {
	sudo docker-compose -f ./docker-compose.yml up -d
}

check_variables $1 $2 $3 $4 $5
validate_variables $1 $2 $3 $4 $5
remove_old_container
create_docker_compose $1 $2 $3 $4 $5
start_filebeat_container
