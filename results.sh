#!/bin/bash
. ./include.sh

mkdir -p $RESULTS_DIR
rsync -az $INSTANCE_PREFIX-master:$REMOTE_HOME/results/ $RESULTS_DIR