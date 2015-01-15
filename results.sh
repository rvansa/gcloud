#!/bin/bash
. ./include.sh

RESULTS_DIR=${1:-$DEFAULT_RESULTS_DIR}
mkdir -p $RESULTS_DIR
rsync -az --progress $INSTANCE_PREFIX-master:$REMOTE_HOME/results/ $RESULTS_DIR
$BROWSER $RESULTS_DIR/html/index.html
