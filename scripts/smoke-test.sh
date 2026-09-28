#!/usr/bin/env bash
# End-to-end checks through the ingress controller, exactly as a visitor hits it.
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"
require curl

failures=0
check() { # description, command...
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then printf '  \033[32mPASS\033[0m %s\n' "$desc"
  else printf '  \033[31mFAIL\033[0m %s\n' "$desc"; failures=$((failures + 1)); fi
}

hides_version() { ! grep -qiE '^server: nginx/[0-9]' <<<"$headers"; }

req() { curl -sS --max-time 10 -H "Host: $HOST" "$@"; }

log "Waiting for the site to answer through the ingress"
for _ in $(seq 1 30); do
  [[ "$(req -o /dev/null -w '%{http_code}' "$BASE_URL/healthz" || true)" == "200" ]] && break
  sleep 2
done

log "Smoke testing $BASE_URL (Host: $HOST)"
headers="$(req -D - -o /dev/null "$BASE_URL/")"
home="$(req "$BASE_URL/")"
asset="$(grep -oE '/assets/[^"]+\.js' <<<"$home" | head -1 || true)"

check "health endpoint returns 200"            test "$(req -o /dev/null -w '%{http_code}' "$BASE_URL/healthz")" = 200
check "home page returns 200"                  test "$(req -o /dev/null -w '%{http_code}' "$BASE_URL/")" = 200
check "home page contains the React root"      grep -q 'id="root"' <<<"$home"
check "deep link falls back to the SPA (200)"  test "$(req -o /dev/null -w '%{http_code}' "$BASE_URL/some/client/route")" = 200
check "hashed JS bundle is served"             test -n "$asset" -a "$(req -o /dev/null -w '%{http_code}' "$BASE_URL$asset")" = 200
check "hashed assets are cached immutably"     grep -qi 'immutable' <<<"$(req -D - -o /dev/null "$BASE_URL$asset")"
check "index.html is not cached"               grep -qi '^cache-control: no-cache' <<<"$headers"
check "CSP header present"                     grep -qi '^content-security-policy:' <<<"$headers"
check "X-Frame-Options DENY"                   grep -qi '^x-frame-options: DENY' <<<"$headers"
check "nosniff header present"                 grep -qi '^x-content-type-options: nosniff' <<<"$headers"
check "nginx version is not disclosed"         hides_version
check "stub_status not exposed publicly"       test "$(req -o /dev/null -w '%{http_code}' "$BASE_URL/stub_status")" = 403

if (( failures > 0 )); then fail "$failures check(s) failed"; fi
log "All smoke tests passed"
