#!/bin/bash
. ./include.sh

echo "Syncing configurations directory..."
rsync -az --progress --exclude '.*/' --exclude '.*' $LOCAL_CONFIG_DIR $INSTANCE_PREFIX-master:$REMOTE_HOME
