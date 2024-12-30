#!/bin/bash

trap "docker stack rm kauriservice" EXIT

FILENAME=kauri.yaml
EXPORT_FILENAME=kauri-temp.yaml

ORIGINAL_STRING=thecmd
QTY1_STRING=theqty1
QTY2_STRING=theqty2

FILENAME2="experiments"
LINES=$(cat $FILENAME2 | grep "^[^#;]")

# Each LINE in the experiment file is one experimental setup
for LINE in $LINES
do
  mkdir ../experiments2/$LINE

  echo '---------------------------------------------------------------'
  echo $LINE
  IFS=':' read -ra split <<< "$LINE"

  sed  "s/${ORIGINAL_STRING}/${split[0]}/g" $FILENAME > $EXPORT_FILENAME
  sed  -i "s/${QTY1_STRING}/${split[1]}/g" $EXPORT_FILENAME
  sed  -i "s/${QTY2_STRING}/${split[2]}/g" $EXPORT_FILENAME

  echo '**********************************************'
  echo "*** This setup needs ${split[3]} physical machines! ***"
  echo '**********************************************'

  for i in {1..3}
  do
        # Deploy experiment
        docker stack deploy -c kauri-temp.yaml kauriservice &
        # Docker startup time + 5*60s of experiment runtime
        sleep 330
        
        # Collect and print results.
        for container in $(docker ps -q -f name="server")
        do
                if [ ! $(docker exec -it $container bash -c "cd Kauri-Public && test -e log0") ]
                then
                  docker exec -it $container bash -c "cd Kauri-Public && tac log* | grep -m1 'commit <block'"
                  docker exec -it $container bash -c "cd Kauri-Public && tac log* | grep -m1 'now state'"
                  docker exec -it $container bash -c "cd Kauri-Public && tac log* | grep -m1 'Average'"
                  docker exec -it $container bash -c "cat Kauri-Public/log* > Kauri-Public/log$i"
                  docker cp $container:/Kauri-Public/log$i ../experiments2/$LINE
                  break
                fi
        done

        docker stack rm kauriservice
        sleep 30

  done
done
