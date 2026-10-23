#!/usr/bin/env bash
set -Eeuo pipefail

PLESK_NODE_BIN="/opt/plesk/node/20/bin"
PATH="$PLESK_NODE_BIN:${PATH:+$PATH:}/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="${SCRIPT_PATH%/*}"
[[ "$SCRIPT_DIR" != "$SCRIPT_PATH" ]] || SCRIPT_DIR="."
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
WEB_ROOT="${ADSO_WEB_ROOT:-}"
API_PANEL_DIR="${ADSO_API_PANEL_DIR:-}"
WEB_ROOT="$(printf '%s' "$WEB_ROOT" | tr -d '\r' | xargs)"
API_PANEL_DIR="$(printf '%s' "$API_PANEL_DIR" | tr -d '\r' | xargs)"

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

[[ -n "$WEB_ROOT" ]] || fail "Set ADSO_WEB_ROOT to the Plesk domain DocumentRoot."
[[ -n "$API_PANEL_DIR" ]] || fail "Set ADSO_API_PANEL_DIR to the API ContentRoot/panel directory."
[[ "$WEB_ROOT" = /* && "$API_PANEL_DIR" = /* ]] || fail "Both deployment directories must be absolute paths."
[[ -d "$WEB_ROOT" ]] || fail "DocumentRoot does not exist: $WEB_ROOT"
[[ "$WEB_ROOT" != "/" && "$API_PANEL_DIR" != "/" ]] || fail "Refusing to publish to a filesystem root."

command -v node >/dev/null 2>&1 || fail "Node.js is required for the Vite build."
command -v npm >/dev/null 2>&1 || fail "npm is required for the Vite build. Check that npm is installed in $PLESK_NODE_BIN."
command -v git >/dev/null 2>&1 || fail "Git is required to record the deployed commit."

cd "$ROOT_DIR"
printf 'Building ADSOLUSOL frontend at %s\n' "$ROOT_DIR"
npm ci
npm run build

DIST_DIR="$ROOT_DIR/dist"
[[ -s "$DIST_DIR/index.html" ]] || fail "Vite did not create dist/index.html."
[[ -d "$DIST_DIR/assets" ]] || fail "Vite did not create dist/assets/."
if ! grep -R -qF "Verificar sitio promocionado" "$DIST_DIR/assets"; then
  fail "Built assets do not contain the site verification card. Nothing was published."
fi

BARE_GIT_DIR="${ADSO_GIT_DIR:-"$ROOT_DIR/../git/ADSOLUSOL"}"
if COMMIT="$(git -C "$ROOT_DIR" rev-parse --short=12 HEAD 2>/dev/null)"; then
  :
elif [[ -d "$BARE_GIT_DIR" ]] && COMMIT="$(git --git-dir="$BARE_GIT_DIR" rev-parse --short=12 HEAD 2>/dev/null)"; then
  :
elif command -v sqlite3 >/dev/null 2>&1 && [[ -r "/usr/local/psa/var/modules/git/git_db.db" ]] && COMMIT="$(sqlite3 /usr/local/psa/var/modules/git/git_db.db "SELECT substr(d.deployedCommitHash, 1, 12) FROM Repositories r JOIN RepositoryDeploymentInfo d ON r.uuid = d.repoUuid WHERE r.name='ADSOLUSOL' LIMIT 1;" 2>/dev/null)" && [[ -n "$COMMIT" ]]; then
  :
else
  COMMIT="${PLESK_DEPLOYMENT_COMMIT:-${GIT_COMMIT:-unknown}}"
fi
BUILT_AT="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
printf '{"commit":"%s","builtAtUtc":"%s"}\n' "$COMMIT" "$BUILT_AT" > "$DIST_DIR/release.json"

mkdir -p "$API_PANEL_DIR"
[[ -w "$WEB_ROOT" ]] || fail "DocumentRoot is not writable by the deployment user: $WEB_ROOT"
[[ -w "$API_PANEL_DIR" ]] || fail "API panel directory is not writable by the deployment user: $API_PANEL_DIR"

# Publish the SPA and its content-hashed assets. Do not delete other site files.
cp -a "$DIST_DIR/." "$WEB_ROOT/"
# /api/panel reads ContentRoot/panel/index.html; its asset URLs resolve from the domain root.
install -m 0644 "$DIST_DIR/index.html" "$API_PANEL_DIR/index.html"

printf 'Published commit %s (%s)\n' "$COMMIT" "$BUILT_AT"
printf 'DocumentRoot: %s\nAPI panel index: %s/index.html\n' "$WEB_ROOT" "$API_PANEL_DIR"
