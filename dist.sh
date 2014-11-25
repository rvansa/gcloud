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
MASTER=${INSTANCE_PREFIX}-master
LAST_ID=`expr $SLAVES - 1`

if [ ! -n "$BENCHMARK_CONFIG" ]; then
	echo "No benchmark specified";
	exit
fi

### Clean old processes
./kill.sh $SLAVES

### Create an associative array of internal IPs
declare -A INTERNAL_IPS
for PAIR in `gcloud compute instances list | tail -n +2 | tr -s ' ' ';' | cut -f 1,4 -d ';'`; do
   INTERNAL_IPS[$(echo $PAIR | cut -f1 -d';')]=$(echo $PAIR | cut -f2 -d';')
done

### Start master node
ssh $MASTER $RADARGUN_HOME/bin/master.sh -c $REMOTE_CONFIG_DIR/radargun/$BENCHMARK_CONFIG -m $MASTER -s $SLAVES

### Start JGroups GOSSIP router on master node
if [ -n "$JGROUPS_JAR" ]; then
   ssh -fn $INSTANCE_PREFIX-master java -cp $JGROUPS_JAR org.jgroups.stack.GossipRouter -port 45123 &
fi

### Create list of nodes for the FILE_PING and TCPPING protocol
#FILE_PING_LIST=$(mktemp)
INITIAL_HOSTS=""
for ID in `seq 0 $LAST_ID`; do
   IP=${INTERNAL_IPS[$INSTANCE_PREFIX-$ID]}
#   echo $INSTANCE_PREFIX-$ID $ID $IP:$JGROUPS_PORT $([ $ID -eq 0 ] && echo "T" || echo "F") >> $FILE_PING_LIST
   if [ -n "$INITIAL_HOSTS" ]; then
      INITIAL_HOSTS="$INITIAL_HOSTS,$IP[$JGROUPS_PORT]"
   else
      INITIAL_HOSTS="$IP[$JGROUPS_PORT]"
   fi
done
#scp -q $FILE_PING_LIST $INSTANCE_PREFIX-master:$REMOTE_HOME/file_ping/$CLUSTER_NAME/slaves.list
#rm $FILE_PING_LIST

### Synchronize etc directory and file_ping directories and start the slave
for ID in `seq 0 $LAST_ID`; do
   ssh $INSTANCE_PREFIX-$ID "rsync -az $INSTANCE_PREFIX-master:$REMOTE_CONFIG_DIR $REMOTE_HOME"
   #ssh $INSTANCE_PREFIX-$ID "rsync -az $INSTANCE_PREFIX-master:$REMOTE_HOME/file_ping/$CLUSTER_NAME $REMOTE_HOME/file_ping"
   ssh $INSTANCE_PREFIX-$ID $RADARGUN_HOME/bin/slave.sh \
      -m $MASTER -n $INSTANCE_PREFIX-$ID -i $ID \
      $ADD_CONFIGS $ADD_JVM_OPTS \
      -J -Djgroups.udp.bind_addr=${INTERNAL_IPS[$INSTANCE_PREFIX-$ID]} \
      -J -Djgroups.tcp.bind_addr=${INTERNAL_IPS[$INSTANCE_PREFIX-$ID]} \
      -J -Djgroups.tcpping.initial_hosts=$INITIAL_HOSTS \
      -J -Djgroups.tcpgossip.initial_hosts=$INSTANCE_PREFIX-master[45123]
done;

