#!/bin/sh
set -eu
# Run as the account that owns the show, without sudo. No root daemon needed.
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
case "$root" in *'%'*|*'"'*|*'\\'*) echo 'Bitte einen einfachen Installationspfad verwenden.' >&2; exit 1;; esac
command -v ruby >/dev/null
ruby -r webrick -e 'puts "Ruby / WEBrick verfügbar"'
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/nulllight.service" <<EOF
[Unit]
Description=NullLight Raspberry Pi Art-Net und Pro DJ Link
After=network.target

[Service]
Type=simple
WorkingDirectory="$root"
ExecStart=/usr/bin/ruby "$root/native/raspberrypi/server.rb"
Environment=NULLLIGHT_BIND=0.0.0.0
Restart=on-failure
RestartSec=3
UMask=0077
NoNewPrivileges=true

[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload
systemctl --user enable --now nulllight.service
printf '%s\n' 'Dienst gestartet. Zugang: journalctl --user -u nulllight -n 10' 'Start ohne Anmeldung (optional): sudo loginctl enable-linger "$USER"'
