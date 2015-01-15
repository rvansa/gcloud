#!/bin/sh
. ./include.sh
LAST_ID=`expr ${1:-$DEFAULT_SLAVES} - 1`

### Release the instances
INSTANCES="$INSTANCE_PREFIX-master"
for ID in `seq 0 $LAST_ID`; do
   INSTANCES="$INSTANCES $INSTANCE_PREFIX-$ID"
done;

echo "Releasing instances $INSTANCES"
gcloud compute instances delete $INSTANCES --quiet --zone $ZONE
gcloud compute instances list # just checking

### Remove the addresses & settings from .ssh/config
ex $HOME/.ssh/config +":g/#GC_BEGIN/,/#GC_END/d" +":wq"
