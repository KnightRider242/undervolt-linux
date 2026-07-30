#!/usr/bin/env bash

have() { command -v "$1" >/dev/null 2>&1; }

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_intel_undervolt() {
  have intel-undervolt || die "intel-undervolt is not installed. Run ./install.sh first."
}

load_msr() {
  sudo modprobe msr || die "Unable to load the Intel msr kernel module."
}

stop_boot_services() {
  if have systemctl; then
    sudo systemctl disable --now intel-undervolt.service 2>/dev/null || true
    sudo systemctl disable --now intel-undervolt-loop.service 2>/dev/null || true
  fi

  if have rc-service; then
    sudo rc-service intel-undervolt-loop stop 2>/dev/null || true
  fi
  if have rc-update; then
    sudo rc-update del intel-undervolt-loop default 2>/dev/null || true
  fi
}
