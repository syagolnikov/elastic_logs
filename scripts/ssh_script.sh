#!/bin/bash
if [[ -z $1 ]]; then
  echo "missing IP"
  exit 0
fi

i=0
while [[ $i -lt 1000 ]]; do
sleep 0.05
#nc -vv -z 192.168.0.82 22
sshpass -p 'YourPassword' ssh admin@$1
sshpass -p 'YourPassword' ssh roger@$1
sshpass -p 'YourPassword' ssh jordan@$1
sshpass -p 'YourPassword' ssh root@$1
sshpass -p 'YourPassword' ssh jack@$1
sshpass -p 'YourPassword' ssh jane@$1
i=$[$i+1]
done
