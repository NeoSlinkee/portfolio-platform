# shellcheck shell=bash
# Shared settings for the helper scripts. Override any of these via env vars.
set -euo pipefail

export CLUSTER_NAME="${CLUSTER_NAME:-portfolio}"
export IMAGE="${IMAGE:-ghcr.io/neoslinkee/portfolio:dev}"
export APP_SRC="${APP_SRC:-../portfolio}"            # checkout of NeoSlinkee/portfolio
export APP_REPO="${APP_REPO:-https://github.com/NeoSlinkee/portfolio.git}"
export INGRESS_NGINX_VERSION="${INGRESS_NGINX_VERSION:-controller-v1.12.1}"
export HOST="${HOST:-portfolio.localtest.me}"
export BASE_URL="${BASE_URL:-http://localhost:8080}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ROOT_DIR

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

require() {
  for bin in "$@"; do
    command -v "$bin" >/dev/null 2>&1 || fail "'$bin' is not installed (see README > Prerequisites)"
  done
}
