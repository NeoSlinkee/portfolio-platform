#!/usr/bin/env bash
# Build the portfolio image from a checkout of the app repo.
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"
require docker git

cd "$ROOT_DIR" || exit 1
if [[ ! -f "$APP_SRC/package.json" ]]; then
  log "App source not found at $APP_SRC, cloning $APP_REPO"
  git clone --depth 1 "$APP_REPO" "$APP_SRC"
fi

log "Building $IMAGE"
docker build \
  --file app/Dockerfile \
  --build-context platform=app \
  --tag "$IMAGE" \
  "$APP_SRC"
