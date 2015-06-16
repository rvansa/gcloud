#!/bin/sh
###########################################
# This is the file you're about to modify #
###########################################

### Common configuration
INSTANCE_PREFIX=jdg
ZONE=us-central1-f
MACHINE_TYPE=n1-standard-1
SHARED_DIR=/mnt/shared
SHARED_DISK_NAME=shared
SHARED_DISK_DEV=/dev/disk/by-id/google-$SHARED_DISK_NAME
REMOTE_HOME=$HOME
#LOCAL_CONFIG_DIR=$HOME/workspace/etc
LOCAL_CONFIG_DIR=$HOME/Development/projects/etc
REMOTE_CONFIG_DIR=$REMOTE_HOME/etc
DEFAULT_SLAVES=32
DEFAULT_RESULTS_DIR=/tmp/results
#BROWSER=firefox
BROWSER=chrome
MAX_CONCURRENCY=32

VERSION=2.1.0-SNAPSHOT
RADARGUN_HOME=$SHARED_DIR/RadarGun-$VERSION

### Configuration for RadarGun jobs
JGROUPS_PORT=7800
JGROUPS_JAR=$SHARED_DIR/RadarGun-2.1.0-SNAPSHOT/plugins/infinispan70/lib/jgroups-3.6.1.Final.jar
CLUSTER_NAME=default

ADD_CONFIGS=""
#ADD_CONFIGS="$ADD_CONFIGS --add-config jdg64:$REMOTE_CONFIG_DIR/ispn-configs/infinispan60/dist-no-tx.xml"
ADD_CONFIGS="$ADD_CONFIGS --add-config jdg65:$REMOTE_CONFIG_DIR/jgroups/infinispan70/jgroups-google.xml"
#ADD_CONFIGS="$ADD_CONFIGS --add-config jdg64:$SHARED_DIR/RadarGun-2.0.0-SNAPSHOT/plugins/jdg63/conf/server.xml"
ADD_CONFIGS="$ADD_CONFIGS --add-config jdg64:$REMOTE_HOME/etc/configs/default/gce.xml"

ADD_JVM_OPTS=""
ADD_JVM_OPTS="$ADD_JVM_OPTS -J -Dinfinispan.jgroups.config=jgroups-google.xml"
ADD_JVM_OPTS="$ADD_JVM_OPTS -J -Djdg.home=$REMOTE_HOME/jboss-datagrid-6.4.0-server"
ADD_JVM_OPTS="$ADD_JVM_OPTS -J -Dserver.config=gce.xml"
ADD_JVM_OPTS="$ADD_JVM_OPTS -J -Dmax.list.print_size=256"
ADD_JVM_OPTS="$ADD_JVM_OPTS -J -Xss228k"
#ADD_JVM_OPTS="$ADD_JVM_OPTS -J -Dsun.tools.attach.attachTimeout=30000"
ADD_JVM_OPTS="$ADD_JVM_OPTS -J -Dlog4j.configuration=file://$HOME/etc/log4j/log4j-debug.xml"
ADD_JVM_OPTS="$ADD_JVM_OPTS -J -verbose:gc -J -XX:+PrintGCDetails -J -XX:+PrintGCTimeStamps -J -XX:+PrintGCCause"


# kill all processes on Ctrl+C
trap 'kill $(jobs -p); exit;' SIGINT
