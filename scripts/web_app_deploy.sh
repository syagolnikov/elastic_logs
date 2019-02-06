#!/bin/bash

sudo docker rm -f $(sudo docker ps -a -q)
i=0

while [[ $i -le 9 ]]; do
	sleep 1
	sudo docker run -d -it --name testserver"$i" -p 808$i:80 -v `pwd`:/usr/local/apache2/htdocs/ httpd:2.4
	i=$[$i+1]
done
