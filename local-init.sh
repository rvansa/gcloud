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
echo "export JAVA_HOME=/etc/alternatives/java_sdk" >> ~/.bashrc

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

### Increase open file limits
echo "* soft nofile 256000" | sudo tee -a /etc/security/limits.conf > /dev/null
echo "* hard nofile 256000" | sudo tee -a /etc/security/limits.conf > /dev/null

### Create directory for FILE_PING protocol
mkdir -p $REMOTE_HOME/file_ping/$CLUSTER_NAME

### Copy JDG server
cp -r $SHARED_DIR/jboss-datagrid-6.4.0-server $REMOTE_HOME
