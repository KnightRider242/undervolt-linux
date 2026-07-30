#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_intel_undervolt
load_msr
sudo intel-undervolt apply
sudo intel-undervolt read

if have systemctl; then
  sudo systemctl daemon-reload
  if systemctl list-unit-files intel-undervolt.service --no-legend 2>/dev/null | grep -q 'intel-undervolt.service'; then
    sudo systemctl enable --now intel-undervolt.service
    systemctl --no-pager --full status intel-undervolt.service || true
  elif systemctl list-unit-files intel-undervolt-loop.service --no-legend 2>/dev/null | grep -q 'intel-undervolt-loop.service'; then
    sudo systemctl enable --now intel-undervolt-loop.service
    systemctl --no-pager --full status intel-undervolt-loop.service || true
  else
    die "No intel-undervolt systemd unit was found. Reinstall with ./install.sh or apply profiles manually."
  fi
elif have rc-update && have rc-service; then
  sudo rc-update add intel-undervolt-loop default
  sudo rc-service intel-undervolt-loop restart
  sudo rc-service intel-undervolt-loop status || true
else
  die "Automatic boot setup currently supports systemd and OpenRC. Use apply-performance.sh manually on this init system."
fi
