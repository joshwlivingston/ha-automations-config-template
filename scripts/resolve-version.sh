#!/usr/bin/env bash
# Pick the ha-automations tag to deploy
#
# Tag:
#   VERSION set                           VERSION
#   DEV=1                                 latest vX.Y.Z or vX.Y.Z.9xxx
#   manual run                            latest vX.Y.Z
#   box runs vX.Y.Z.9xxx                  box's tag
#     and it is on REPO_URL
#     and it is later than latest vX.Y.Z
#   otherwise                             latest vX.Y.Z
#
# Prints:
#   version=<tag>
#   dev=<1 or empty>
#
# Usage: scripts/resolve-version.sh >> "$GITHUB_OUTPUT"
#
# Settings, read from the environment:
#   REPO_URL      package source, e.g. https://github.com/you/ha-automations (required)
#   VERSION       tag to deploy (default: latest)
#   DEV           set to 1 to include dev tags
#   HA_SSH        ssh target, e.g. root@homeassistant.local (needed for the box's tag)
#   HA_SSH_PORT   ssh port (default 22)
#   ADDON_SLUG    AppDaemon add-on slug (default a0d7b954_appdaemon)
set -euo pipefail

: "${REPO_URL:?set REPO_URL (e.g. https://github.com/you/ha-automations)}"
HA_SSH_PORT=${HA_SSH_PORT:-22}
ADDON_SLUG=${ADDON_SLUG:-a0d7b954_appdaemon}
DEV=${DEV:-}

release='^v[0-9]+\.[0-9]+\.[0-9]+$'
dev='^v[0-9]+\.[0-9]+\.[0-9]+\.9[0-9]{3}$'

# --- Helpers ---

# Prints a message to stderr and exits with status 1
die() {
  echo "$1" >&2
  exit 1
}

# Prints the ha-automations tag the box runs, or nothing if it runs none from REPO_URL
deployed_tag() {
  local packages p prefix="ha-automations@$REPO_URL/archive/refs/tags/"
  packages=$(ssh -p "$HA_SSH_PORT" "${HA_SSH:?set HA_SSH (e.g. root@homeassistant.local)}" \
    "curl -fsS -H \"Authorization: Bearer \$SUPERVISOR_TOKEN\" http://supervisor/addons/$ADDON_SLUG/info | jq -r '.data.options.python_packages // [] | .[]'") \
    || die "could not read $ADDON_SLUG options from $HA_SSH"
  while read -r p; do
    if [[ "$p" == "$prefix"*.tar.gz ]]; then
      p=${p#"$prefix"}
      echo "${p%.tar.gz}"
      return
    fi
  done <<< "$packages"
}

# --- Pick a tag ---

if [[ -n "${VERSION:-}" ]]; then
  tag=$VERSION
else
  tags=$(git ls-remote --tags --refs "$REPO_URL" 'v*' | sed 's|.*refs/tags/||')
  pattern=$release
  [[ "$DEV" == 1 ]] && pattern="$release|$dev"
  tag=$(grep -E "$pattern" <<< "$tags" | sort -V | tail -1) || true
  [[ -n "$tag" ]] || die "no matching tags on $REPO_URL (dev=${DEV:-0})"

  # Scheduled and push runs keep a later dev tag on the box, if it still exists
  if [[ "$DEV" != 1 && "${GITHUB_EVENT_NAME:-}" != workflow_dispatch ]]; then
    current=$(deployed_tag)
    if [[ "$current" =~ $dev && "$current" != "$tag" ]] && grep -qxF "$current" <<< "$tags" \
       && [[ "$(printf '%s\n' "$tag" "$current" | sort -V | tail -1)" == "$current" ]]; then
      echo "Box runs dev tag $current, later than $tag. Keeping it." >&2
      tag=$current
      DEV=1
    fi
  fi
fi

echo "version=$tag"
echo "dev=$DEV"
