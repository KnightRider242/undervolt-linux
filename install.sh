#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
UPSTREAM_REPO="https://github.com/kitsunyan/intel-undervolt.git"

log() { printf '\n==> %s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

if [[ ${EUID} -eq 0 ]]; then
  die "Run this installer as your normal user, not as root. It will request sudo when needed."
fi

[[ -r /proc/cpuinfo ]] || die "/proc/cpuinfo is unavailable; this installer supports native Linux systems only."
grep -q '^vendor_id[[:space:]]*: GenuineIntel' /proc/cpuinfo \
  || die "This profile is only for supported Intel CPUs. AMD CPUs require a different tool."

case "$(uname -m)" in
  x86_64|amd64) ;;
  *) die "intel-undervolt is intended for x86-64 Intel systems; detected $(uname -m)." ;;
esac

have sudo || die "sudo is required. Install/configure sudo, then run this script again."

install_build_dependencies() {
  log "Installing build dependencies for the detected distribution"
  if have apt-get; then
    sudo apt-get update
    sudo apt-get install -y build-essential git pkg-config
  elif have dnf; then
    sudo dnf install -y gcc make git pkgconf-pkg-config
  elif have yum; then
    sudo yum install -y gcc make git pkgconfig
  elif have pacman; then
    sudo pacman -S --needed --noconfirm base-devel git pkgconf
  elif have zypper; then
    sudo zypper --non-interactive install gcc make git pkg-config
  elif have apk; then
    sudo apk add build-base git pkgconf
  elif have xbps-install; then
    sudo xbps-install -Sy base-devel git pkg-config
  elif have emerge; then
    sudo emerge --noreplace dev-vcs/git sys-devel/gcc sys-devel/make virtual/pkgconfig
  elif have eopkg; then
    sudo eopkg install -y -c system.devel git
  else
    die "No supported package manager was detected. Install gcc, make, git, and pkg-config, then rerun."
  fi
}

try_native_package() {
  log "Checking for a native intel-undervolt package"
  if have dnf; then
    sudo dnf install -y intel-undervolt
  elif have yum; then
    sudo yum install -y intel-undervolt
  elif have pacman; then
    sudo pacman -S --needed --noconfirm intel-undervolt
  elif have zypper; then
    sudo zypper --non-interactive install intel-undervolt
  elif have apt-get && apt-cache show intel-undervolt >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y intel-undervolt
  elif have xbps-install; then
    sudo xbps-install -Sy intel-undervolt
  elif have apk; then
    sudo apk add intel-undervolt
  elif have emerge; then
    sudo emerge --noreplace sys-power/intel-undervolt
  else
    return 1
  fi
}

build_from_source() {
  install_build_dependencies

  local workdir configure_args=()
  workdir="$(mktemp -d)"
  trap 'rm -rf "${workdir:-}"' EXIT

  if have systemctl; then
    configure_args+=(--enable-systemd)
  elif have rc-update; then
    configure_args+=(--enable-openrc)
  elif have loginctl; then
    configure_args+=(--enable-elogind)
  fi

  log "Building intel-undervolt from the official upstream source"
  git clone --depth 1 "$UPSTREAM_REPO" "$workdir/intel-undervolt"
  (
    cd "$workdir/intel-undervolt"
    ./configure "${configure_args[@]}"
    make -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '1')"
    sudo make install
  )
}

if have intel-undervolt; then
  log "intel-undervolt is already installed at $(command -v intel-undervolt)"
elif ! try_native_package; then
  warn "No native package was available from the enabled repositories."
  build_from_source
fi

have intel-undervolt \
  || die "intel-undervolt was installed but is not visible in PATH. Check /usr/local/bin and rerun."

log "Loading the Intel MSR kernel module"
sudo modprobe msr || die "Could not load the msr module. Check kernel support and Secure Boot/kernel restrictions."

if [[ -f /etc/intel-undervolt.conf ]]; then
  backup="/etc/intel-undervolt.conf.backup.$(date +%Y%m%d-%H%M%S)"
  sudo cp -a /etc/intel-undervolt.conf "$backup"
  log "Backed up the existing configuration to $backup"
fi

sudo install -m 0644 \
  "$SCRIPT_DIR/intel-undervolt-performance.conf" \
  /etc/intel-undervolt.conf

log "Installation complete"
printf '%s\n' \
  "The Performance profile is installed but has NOT been enabled at boot." \
  "Test it once with:" \
  "  $SCRIPT_DIR/apply-performance.sh" \
  "After stability testing, enable boot application with:" \
  "  $SCRIPT_DIR/enable-at-boot.sh"

printf '\nCurrent hardware values:\n'
sudo intel-undervolt read || true
