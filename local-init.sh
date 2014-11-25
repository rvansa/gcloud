#!/bin/sh
##############################
# Locally provision the node #
##############################
. ./include.sh

### Mount the shared disk
if [ ! -d $SHARED_DIR ]; then
	sudo mkdir $SHARED_DIR --mode=777 
fi
sudo mount $SHARED_DISK_DEV $SHARED_DIR

### Install Java
sudo rpm -i $SHARED_DIR/install/*

### Install ssh keys for connection between nodes
ONE_TIME_KEY=$INSTANCE_PREFIX-one-time
cat $ONE_TIME_KEY.pub >> $REMOTE_HOME/.ssh/authorized_keys
echo "Host *
    IdentityFile $REMOTE_HOME/jdg-one-time
    UserKnownHostsFile=/dev/null
    CheckHostIP=no
    StrictHostKeyChecking=no
    LogLevel ERROR
" >> $REMOTE_HOME/.ssh/config
chmod 600 $REMOTE_HOME/.ssh/config

### Create directory for FILE_PING protocol
mkdir -p $REMOTE_HOME/file_ping/$CLUSTER_NAME
