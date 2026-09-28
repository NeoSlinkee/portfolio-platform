#!/usr/bin/env bash
# Create the local cluster (idempotent), build the site image and deploy it.
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"
require docker kind kubectl git

cd "$ROOT_DIR" || exit 1

if kind get clusters | grep -qx "$CLUSTER_NAME"; then
  log "kind cluster '$CLUSTER_NAME' already exists"
else
  log "Creating kind cluster '$CLUSTER_NAME'"
  kind create cluster --config cluster/kind-config.yaml --wait 120s
fi

log "Installing ingress-nginx ($INGRESS_NGINX_VERSION)"
kubectl apply -f "https://raw.githubusercontent.com/kubernetes/ingress-nginx/${INGRESS_NGINX_VERSION}/deploy/static/provider/kind/deploy.yaml"
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=180s

"$ROOT_DIR/scripts/build.sh"

log "Loading $IMAGE into the cluster"
kind load docker-image "$IMAGE" --name "$CLUSTER_NAME"

"$ROOT_DIR/scripts/deploy.sh" kind

log "Done. Open http://$HOST:8080"
