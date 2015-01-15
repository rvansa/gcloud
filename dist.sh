#!/bin/sh
###############################################
# Start RadarGun benchmark                    #
# Usage: ./dist.sh benchmark.xml [num-slaves] #
###############################################
. ./include.sh

VERSION=2.0.0-SNAPSHOT
RADARGUN_HOME=$SHARED_DIR/RadarGun-$VERSION
BENCHMARK_CONFIG=$1
SLAVES=${2:-$DEFAULT_SLAVES}
MASTER=$INSTANCE_PREFIX-master
LAST_ID=`expr $SLAVES - 1`

if [ ! -n "$BENCHMARK_CONFIG" ]; then
	echo "No benchmark specified";
	exit
fi

### Clean old processes
echo "Killing old processes..."
./kill.sh $SLAVES

### Create an associative array of internal IPs
echo "Retrieving internal IP addresses"
declare -A INTERNAL_IPS
for PAIR in `gcloud compute instances list | tail -n +2 | tr -s ' ' ';' | cut -f 1,4 -d ';'`; do
   INTERNAL_IPS[$(echo $PAIR | cut -f1 -d';')]=$(echo $PAIR | cut -f2 -d';')
done

### Start master node
echo "Starting RadarGun Master and GossipRouter..."
ssh $MASTER $RADARGUN_HOME/bin/master.sh -c $REMOTE_CONFIG_DIR/radargun/$BENCHMARK_CONFIG -m $MASTER -s $SLAVES

### Start JGroups GOSSIP router on master node
if [ -n "$JGROUPS_JAR" ]; then
   ssh -fn $INSTANCE_PREFIX-master java -cp $JGROUPS_JAR org.jgroups.stack.GossipRouter -port 45123 &
fi

### Create list of nodes for the FILE_PING and TCPPING protocol
#FILE_PING_LIST=$(mktemp)
INITIAL_HOSTS=""
HOTROD_SERVERS=""
for ID in `seq 0 $LAST_ID`; do
   IP=${INTERNAL_IPS[$INSTANCE_PREFIX-$ID]}
#   echo $INSTANCE_PREFIX-$ID $ID $IP:$JGROUPS_PORT $([ $ID -eq 0 ] && echo "T" || echo "F") >> $FILE_PING_LIST
   if [ -n "$INITIAL_HOSTS" ]; then
      INITIAL_HOSTS="$INITIAL_HOSTS,$IP[$JGROUPS_PORT]"
   else
      INITIAL_HOSTS="$IP[$JGROUPS_PORT]"
   fi
   HOTROD_SERVERS="${HOTROD_SERVERS}${IP}:11222\\;"
done
#scp -q $FILE_PING_LIST $INSTANCE_PREFIX-master:$REMOTE_HOME/file_ping/$CLUSTER_NAME/slaves.list
#rm $FILE_PING_LIST

### Synchronize etc directory and file_ping directories and start the slave
echo "Starting slave nodes..."

function start_slave() {
   INSTANCE=$1
   ID=$2
   ATTEMPT=0
   until ssh $INSTANCE "rsync -az $INSTANCE_PREFIX-master:$REMOTE_CONFIG_DIR $REMOTE_HOME"; do
      echo "Failed to sync with master on $INSTANCE";
      sleep 1;
      if [ $ATTEMPT -gt 10 -a -n "$BEEP_SOUND" ]; then
         aplay $BEEP_SOUND;
      fi
      ATTEMPT=`expr $ATTEMPT + 1`
   done
   #ssh $INSTANCE "rsync -az $INSTANCE_PREFIX-master:$REMOTE_HOME/file_ping/$CLUSTER_NAME $REMOTE_HOME/file_ping"
   until ssh $INSTANCE 'rm /tmp/hsperfdata_$USER/* 2> /dev/null || true'; do sleep 1; done;
   until ssh $INSTANCE slave${ID}_BIND_ADDRESS=${INTERNAL_IPS[$INSTANCE]} $RADARGUN_HOME/bin/slave.sh \
      -m $MASTER -n slave$ID -i $ID \
      $ADD_CONFIGS $ADD_JVM_OPTS \
      -J -Djava.managed.server.id=`uuid -v 4` \
      -J -Djgroups.udp.mcast_addr=224.1.2.3 \
      -J -Djgroups.udp.bind_addr=${INTERNAL_IPS[$INSTANCE]} \
      -J -Djgroups.tcp.bind_addr=${INTERNAL_IPS[$INSTANCE]} \
      -J -Djgroups.tcpping.initial_hosts=$INITIAL_HOSTS \
      -J -Djgroups.tcpgossip.initial_hosts=$INSTANCE_PREFIX-master[45123] \
      -J "-Dsite.servers.hotrod=$HOTROD_SERVERS"; do
      echo "Failed to start slave on $INSTANCE";
      sleep 1;
   done
}

for ID in `seq 0 $LAST_ID`; do
   start_slave $INSTANCE_PREFIX-$ID $ID &
   if [ `expr \( $ID + 1 \) % $MAX_CONCURRENCY` -eq 0 ]; then
      wait
   fi
done
wait

if [ -n "$ALERT_SOUND" ]; then
	aplay $ALERT_SOUND
fi

