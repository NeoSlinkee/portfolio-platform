#!/usr/bin/env bash
# Apply an overlay (kind | aks), wait for the rollout, then smoke test.
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"
require kubectl

OVERLAY="${1:-kind}"
cd "$ROOT_DIR" || exit 1

log "Applying overlay '$OVERLAY'"
kubectl apply -k "k8s/overlays/$OVERLAY"
kubectl -n portfolio rollout status deployment/portfolio --timeout=180s
kubectl -n portfolio get pods,svc,ingress -o wide

if [[ "$OVERLAY" == "kind" ]]; then
  "$ROOT_DIR/scripts/smoke-test.sh"
fi
