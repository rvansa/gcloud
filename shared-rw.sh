#!/bin/sh
###############################################################
# Reconnect the shared drive into read-write (exclusive) mode #
# Usage: ./shared-rw.sh [num-slaves]                          #
###############################################################
. ./include.sh

LAST_ID=`expr ${1:-$DEFAULT_SLAVES} - 1`

echo "Unmounting drives..."
ssh -tt $INSTANCE_PREFIX-master sudo umount $SHARED_DISK_DEV &
for ID in `seq 0 $LAST_ID`; do
   ssh -tt $INSTANCE_PREFIX-$ID sudo umount $SHARED_DISK_DEV &
   if [ `expr \( $ID + 1 \) % $MAX_CONCURRENCY` -eq 0 ]; then
      wait
   fi
done
wait

gcloud compute instances detach-disk $INSTANCE_PREFIX-master --disk $SHARED_DISK_NAME &
for ID in `seq 0 $LAST_ID`; do
   gcloud compute instances detach-disk $INSTANCE_PREFIX-$ID --disk $SHARED_DISK_NAME &
   if [ `expr \( $ID + 1 \) % $MAX_CONCURRENCY` -eq 0 ]; then
      wait
   fi
done

echo "Waiting to detach all drives"
wait

echo "Attaching to $INSTANCE_PREFIX-master..."
gcloud compute instances attach-disk $INSTANCE_PREFIX-master --disk $SHARED_DISK_NAME --mode rw --device-name=$SHARED_DISK_NAME --zone=$ZONE
ssh -tt $INSTANCE_PREFIX-master sudo mount $SHARED_DISK_DEV $SHARED_DIR
