#!/bin/sh
. ./include.sh
LAST_ID=`expr ${1:-$DEFAULT_SLAVES} - 1`

### Release the instances
gcloud compute instances delete $INSTANCE_PREFIX-master --quiet --zone $ZONE &
for ID in `seq 0 $LAST_ID`; do
	gcloud compute instances delete $INSTANCE_PREFIX-$ID --quiet --zone $ZONE &
done;
wait
gcloud compute instances list # just checking

### Remove the addresses & settings from .ssh/config
ex $HOME/.ssh/config +":g/#GC_BEGIN/,/#GC_END/d" +":wq"
