#!/bin/bash

# Based on https://github.com/h0ek/x-resize

set -eux

export DEBIAN_FRONTEND="noninteractive"

# install the qemu-kvm Guest Additions.
apt-get install -y qemu-guest-agent spice-vdagent xinput xserver-xorg-input-evdev

SCRIPT_FILE="/usr/local/bin/x-resize"
XORG_DIR="/etc/X11/xorg.conf.d"
EVDEV_FILE="${XORG_DIR}/70-tablet-evdev.conf"
SERVICE_FILE="/etc/systemd/system/x-resize.service"

# --- Xorg InputClass: force tablets to evdev Absolute ---
mkdir -p "${XORG_DIR}"
tee "${EVDEV_FILE}" >/dev/null <<'EOF'
Section "InputClass"
    Identifier "QEMU USB Tablet via evdev"
    MatchProduct "QEMU QEMU USB Tablet"
    Driver "evdev"
    Option "Mode" "Absolute"
EndSection

Section "InputClass"
    Identifier "SPICE vdagent tablet via evdev"
    MatchProduct "spice vdagent tablet"
    Driver "evdev"
    Option "Mode" "Absolute"
EndSection
EOF

# --- RandR listener + evdev calibration ---
install -m 755 /dev/null "${SCRIPT_FILE}"
cat >"${SCRIPT_FILE}" <<'EOF'
#!/usr/bin/env bash
# x-resize-xfce: XFCE/Xorg RandR auto-resize + evdev axis calibration (user mode)
# Fixes absolute-pointer offset when SPICE yields odd modes (e.g., 1809x1055).
# Per RandR event:
#   1) xrandr --auto on active output
#   2) read current WxH
#   3) set "Evdev Axis Calibration" = 0..W-1, 0..H-1 on tablets
#   4) apply a no-op transform to force Xorg to re-evaluate maps

set -euo pipefail
log(){ logger -t x-resize-xfce -- "$*"; echo "[x-resize-xfce] $*"; }

# Require Xorg
if [ "${XDG_SESSION_TYPE:-}" != "x11" ]; then
  log "Not X11 (XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-unset}); exiting."
  exit 0
fi

: "${DISPLAY:?DISPLAY not set}"
: "${XAUTHORITY:=${HOME}/.Xauthority}"
export DISPLAY XAUTHORITY

TABLETS=("QEMU QEMU USB Tablet" "spice vdagent tablet")

pick_output(){ xrandr --current | awk '/ connected primary/{print $1;exit} / connected/{print $1;exit}'; }
current_mode(){
  local m
  m="$(xrandr | awk '/\*/{print $1;exit}')"   # e.g., 1809x1055
  if [ -z "$m" ]; then
    m="$(xrandr | awk -F'current ' 'NR==1{split($2,a,","); gsub(/ /,"",a[1]); print a[1]}')"  # Screen 0: current WxH
  fi
  echo "$m"
}

calibrate_evdev_to(){
  local wh="$1" w h
  w="${wh%x*}"; h="${wh#*x}"
  for dev in "${TABLETS[@]}"; do
    if xinput --list --name-only | grep -Fxq "$dev"; then
      log "Calibrate $dev -> ${w}x${h}"
      xinput --set-prop "$dev" "Evdev Axis Calibration" 0 $((w-1)) 0 $((h-1)) 2>/dev/null || true
      xinput --set-prop "$dev" "Evdev Axis Inversion" 0 0 2>/dev/null || true
    fi
  done
}

apply_once(){
  local out cur
  out="$(pick_output)"; [ -n "$out" ] || { log "No connected outputs"; return 0; }

  # 1) Let SPICE propose size
  xrandr --output "$out" --auto || true

  # 2) Calibrate evdev axes to current screen size
  cur="$(current_mode)"
  [ -n "$cur" ] && calibrate_evdev_to "$cur"

  # 3) No-op transform (forces Xorg to re-evaluate maps). No flicker.
  xrandr --output "$out" --transform 1,0,0,0,1,0,0,0,1 || true
}

# Initial pass
apply_once

# Debounce (300 ms)
last=0
debounce_ms=300
now_ms(){ date +%s%3N 2>/dev/null || echo $(( $(date +%s)*1000 )); }
should_run(){ local n; n=$(now_ms); if (( n-last >= debounce_ms )); then last=$n; return 0; fi; return 1; }

log "Listening for RandR changes on ${DISPLAY} ..."
xev -root -event randr 2>/dev/null | grep --line-buffered 'XRROutputChangeNotifyEvent' | \
while read -r _; do
  if should_run; then
    apply_once
  fi
done
EOF


# Define the system path
cat >"${SERVICE_FILE}" <<EOF
[Unit]
Description=x-resize (XFCE/Kali): Global Xorg RandR + Calibration (Root)
After=display-manager.service

[Service]
Type=simple
User=root
Group=root
Environment=DISPLAY=:0
Environment=XAUTHORITY=/var/run/lightdm/root/:0
Environment=XDG_SESSION_TYPE=x11
ExecStart=${SCRIPT_FILE}
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable x-resize.service

# reboot.
nohup bash -c "ps -eo pid,comm | awk '/sshd/{print \$1}' | xargs kill; sync; reboot"
