#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_intel_undervolt
stop_boot_services

cat <<'CONF' | sudo tee /etc/intel-undervolt.conf >/dev/null
enable no
undervolt 0 'CPU' 0
undervolt 1 'GPU' 0
undervolt 2 'CPU Cache' 0
undervolt 3 'System Agent' 0
undervolt 4 'Analog I/O' 0
interval 5000
daemon undervolt:once
CONF

load_msr
sudo intel-undervolt apply || true
sudo intel-undervolt read || true

printf '%s\n' \
  "Automatic undervolting is disabled and voltage offsets were reset to 0 mV." \
  "Reboot if firmware power limits do not immediately return to their defaults."
