#!/bin/sh
##########################################
# Allocate & provision instances         #
# Usage: ./create-instances [num-slaves] #
##########################################
. ./include.sh

SLAVES=${1:-$DEFAULT_SLAVES}
LAST_ID=`expr $SLAVES - 1`
SSH_CONFIG=$HOME/.ssh/config

### Allocate nodes

function allocate_instance() {
   INSTANCE=$1
   gcloud compute instances create $INSTANCE \
	   --machine n1-standard-2 \
	   --image rhel-6 \
	   --disk name=shared mode=ro device-name=shared
   echo "Instance ${INSTANCE} created."
}

echo "Allocating master + $SLAVES slaves"
allocate_instance ${INSTANCE_PREFIX}-master &
for ID in `seq 0 $LAST_ID`; do
	allocate_instance ${INSTANCE_PREFIX}-$ID &
done;
wait

### Add records to ~/.ssh/config
function add_to_ssh_config() {
   echo "Host $1
    HostName $2
    IdentityFile $HOME/.ssh/google_compute_engine
    UserKnownHostsFile=/dev/null
    CheckHostIP=no
    StrictHostKeyChecking=no
    LogLevel ERROR
" >> $SSH_CONFIG
}

echo "#GC_BEGIN" >> $SSH_CONFIG
for PAIR in `gcloud compute instances list | tail -n +2 | tr -s ' ' ';' | cut -f 1,5 -d ";"`; do
   INSTANCE=$(echo $PAIR | cut -f1 -d";")
   EXTERNAL_IP=$(echo $PAIR | cut -f2 -d";")
   add_to_ssh_config $INSTANCE $EXTERNAL_IP
done;
echo "#GC_END" >> $SSH_CONFIG

### Generate one time key that will be used only for connecting inside the cluster
ONE_TIME_KEY=/tmp/${INSTANCE_PREFIX}-one-time
rm $ONE_TIME_KEY* # in case it exists
ssh-keygen -t rsa -C ${INSTANCE_PREFIX}"-one-time" -f $ONE_TIME_KEY -P ""

### Wait until we can connect
until ssh $INSTANCE_PREFIX-master "echo Connected"; do
   echo "Connection to $INSTANCE_PREFIX-master not ready, waiting one second..."
   sleep 1
done

### Call init_instance for all the nodes in parallel
function init_instance() {
   INSTANCE=$1
   ONE_TIME_KEY=$2
   rsync -az ./*.sh ${ONE_TIME_KEY}* $INSTANCE:$REMOTE_HOME
   ssh -tt $INSTANCE $REMOTE_HOME/local-init.sh
   echo "Instance ${INSTANCE} initialized."
}

init_instance $INSTANCE_PREFIX-master $ONE_TIME_KEY &
for ID in `seq 0 $LAST_ID`; do
   init_instance jdg-$ID $ONE_TIME_KEY &
done;

wait
rm ${ONE_TIME_KEY}*

### Synchronize configuration directories on master node
./sync-config.sh
