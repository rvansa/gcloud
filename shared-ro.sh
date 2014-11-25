#!/bin/sh
#############################################################
# Reconnect the shared drive into read-only (sharable) mode #
# Usage: ./shared-ro.sh [num-slaves]                        #
#############################################################
. ./include.sh

LAST_ID=`expr ${1:-$DEFAULT_SLAVES} - 1`

echo "Detaching from ${INSTANCE_PREFIX}-master..."
ssh -t ${INSTANCE_PREFIX}-master 'sudo umount '$SHARED_DIR
gcloud compute instances detach-disk ${INSTANCE_PREFIX}-master --disk shared

echo "Attaching to instances..."
gcloud compute instances attach-disk ${INSTANCE_PREFIX}-master --disk shared --mode ro --device-name=shared --zone=$ZONE &
for ID in `seq 0 $LAST_ID`; do
	gcloud compute instances attach-disk ${INSTANCE_PREFIX}-${ID} --disk shared --mode ro --device-name=shared --zone=$ZONE &
done
wait

echo "Mounting drives..."
ssh -tt ${INSTANCE_PREFIX}-master 'sudo mount $SHARED_DISK_DEV '$SHARED_DIR &
for ID in `seq 0 $LAST_ID`; do
	ssh -tt ${INSTANCE_PREFIX}-$ID 'sudo mount $SHARED_DISK_DEV '$SHARED_DIR &
done
wait

