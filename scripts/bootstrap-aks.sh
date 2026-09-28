#!/usr/bin/env bash
# OPTIONAL, PAID. One-time cluster setup after `terraform apply` in
# infra/terraform/aks: ingress controller, cert-manager and the app itself.
# Run with your own (admin) Entra ID login, not the CI deploy identity.
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"
require az kubectl kubelogin helm terraform

cd "$ROOT_DIR/infra/terraform/aks" || exit 1
rg="$(terraform output -raw resource_group_name)"
cluster="$(terraform output -raw cluster_name)"

log "Fetching credentials for $cluster"
az aks get-credentials -g "$rg" -n "$cluster" --overwrite-existing
kubelogin convert-kubeconfig -l azurecli

log "Installing ingress-nginx (public Azure load balancer)"
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.externalTrafficPolicy=Local \
  --set controller.config.ssl-redirect="true" \
  --wait

log "Installing cert-manager"
helm upgrade --install cert-manager cert-manager \
  --repo https://charts.jetstack.io \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=true \
  --wait

cd "$ROOT_DIR" || exit 1
"$ROOT_DIR/scripts/deploy.sh" aks

ip="$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
log "Point an A record for k8s.maarsch.net at $ip; cert-manager will then issue the TLS certificate."
log "When the demo is over: (cd infra/terraform/aks && terraform destroy) to stop all charges."
