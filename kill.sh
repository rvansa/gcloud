#!/bin/bash
#################################
# Kills RadarGun processes      #
# Usage: ./kill.sh [num-slaves] #
#################################
. ./include.sh

SLAVES=${2:-$DEFAULT_SLAVES}
LAST_ID=`expr $SLAVES - 1`

for ID in `seq 0 $LAST_ID`; do
   ssh $INSTANCE_PREFIX-$ID 'kill `jps | grep Slave | cut -f 1 -d " "`' 2> /dev/null
done
ssh $INSTANCE_PREFIX-master 'kill `jps | grep -e "LaunchMaster\|GossipRouter" | cut -f 1 -d " "`' 2> /dev/null