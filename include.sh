#!/bin/sh
###########################################
# This is the file you're about to modify #
###########################################

### Common configuration
INSTANCE_PREFIX=jdg
ZONE=us-central1-f
SHARED_DIR=/mnt/shared
SHARED_DISK_DEV=/dev/disk/by-id/google-shared
REMOTE_HOME=$HOME
LOCAL_CONFIG_DIR=$HOME/workspace/etc
REMOTE_CONFIG_DIR=$REMOTE_HOME/etc
DEFAULT_SLAVES=2
RESULTS_DIR=/tmp/results

### Configuration for RadarGun jobs
JGROUPS_PORT=7800
JGROUPS_JAR=$SHARED_DIR/RadarGun-2.0.0-SNAPSHOT/plugins/infinispan70/lib/jgroups-3.6.0.Final.jar
CLUSTER_NAME=default

ADD_CONFIGS=""
ADD_CONFIGS="$ADD_CONFIGS --add-config infinispan70:$REMOTE_CONFIG_DIR/ispn-configs/infinispan70/dist-no-tx.xml"
ADD_CONFIGS="$ADD_CONFIGS --add-config infinispan70:$REMOTE_CONFIG_DIR/jgroups/infinispan70/jgroups-google.xml"

ADD_JVM_OPTS=""
ADD_JVM_OPTS="$ADD_JVM_OPTS -J -Dinfinispan.jgroups.config=jgroups-google.xml"
#ADD_JVM_OPTS="$ADD_JVM_OPTS -J -Dlog4j.configuration=file://$HOME/etc/log4j/log4j-jgroups.xml"
