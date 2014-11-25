#!/bin/sh
###############################################################
# Reconnect the shared drive into read-write (exclusive) mode #
# Usage: ./shared-rw.sh [num-slaves]                          #
###############################################################
. ./include.sh

LAST_ID=`expr ${1:-$DEFAULT_SLAVES} - 1`

echo "Unmounting drives..."
ssh -t ${INSTANCE_PREFIX}-master 'sudo umount '$SHARED_DIR
for ID in `seq 0 $LAST_ID`; do
	ssh -t ${INSTANCE_PREFIX}-$ID 'sudo umount '$SHARED_DIR
done

gcloud compute instances detach-disk ${INSTANCE_PREFIX}-master --disk shared &
for ID in `seq 0 $LAST_ID`; do
	gcloud compute instances detach-disk ${INSTANCE_PREFIX}-$ID --disk shared &
done

echo "Waiting to detach all drives"
wait

echo "Attaching to ${INSTANCE_PREFIX}-master..."
gcloud compute instances attach-disk ${INSTANCE_PREFIX}-master --disk shared --mode rw --device-name=shared --zone=$ZONE
ssh -t ${INSTANCE_PREFIX}-master 'sudo mount $SHARED_DISK_DEV '$SHARED_DIR
