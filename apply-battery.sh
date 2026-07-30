#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_intel_undervolt
load_msr
sudo install -m 0644 "$SCRIPT_DIR/intel-undervolt-battery.conf" /etc/intel-undervolt.conf
sudo intel-undervolt apply
sudo intel-undervolt read
