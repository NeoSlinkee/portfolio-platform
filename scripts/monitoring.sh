#!/usr/bin/env bash
# Optional: Prometheus + Grafana on the local cluster (free, runs in kind).
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"
require helm kubectl

cd "$ROOT_DIR" || exit 1
log "Installing kube-prometheus-stack into namespace 'monitoring'"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null
helm repo update >/dev/null
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --values monitoring/values.yaml \
  --wait --timeout 10m

kubectl apply -f monitoring/servicemonitor.yaml -f monitoring/prometheusrule.yaml -f monitoring/grafana-dashboard.yaml

log "Grafana:    kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80"
log "            then http://localhost:3000 (admin / see monitoring/values.yaml)"
log "Prometheus: kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090"
