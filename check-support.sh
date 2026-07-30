#!/usr/bin/env bash
set -u

printf 'Architecture: %s\n' "$(uname -m)"
printf 'Kernel:       %s\n' "$(uname -sr)"
printf 'CPU vendor:   %s\n' "$(awk -F: '/^vendor_id/{gsub(/^[ \t]+/,"",$2); print $2; exit}' /proc/cpuinfo 2>/dev/null)"
printf 'CPU model:    %s\n' "$(awk -F: '/^model name/{gsub(/^[ \t]+/,"",$2); print $2; exit}' /proc/cpuinfo 2>/dev/null)"

if command -v systemctl >/dev/null 2>&1; then
  printf 'Init support: systemd\n'
elif command -v rc-update >/dev/null 2>&1; then
  printf 'Init support: OpenRC\n'
else
  printf 'Init support: manual apply only\n'
fi

if command -v intel-undervolt >/dev/null 2>&1; then
  printf 'Tool:         %s\n' "$(command -v intel-undervolt)"
  sudo modprobe msr 2>/dev/null || true
  printf '\nCurrent values:\n'
  sudo intel-undervolt read || true
else
  printf 'Tool:         not installed\n'
fi
