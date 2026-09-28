#!/usr/bin/env bash
# Delete the local cluster and everything in it.
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"
require kind
log "Deleting kind cluster '$CLUSTER_NAME'"
kind delete cluster --name "$CLUSTER_NAME"
