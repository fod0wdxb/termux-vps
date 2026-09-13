#!/data/data/com.termux/files/usr/bin/bash
# boot-autostart.sh — for the Termux:Boot app (phone restart survival).
# Install (once):  cp termux-vps/boot-autostart.sh ~/.termux/boot/10-vps
# Termux:Boot runs it ~30s after boot; the VPS comes up headless.
# SSH access works; the banner is not shown (no screen session yet).

SCRIPTS="$HOME/termux-vps"
[ -f "$SCRIPTS/vps" ] || SCRIPTS="$HOME/.local/share/termux-vps"

if [ -x "$SCRIPTS/vps" ]; then
    nohup "$SCRIPTS/vps" >/dev/null 2>&1 &
else
    # fall back: minimal headless start (sshd only, no Termux scripts)
    termux-wake-lock
    tailscaled-start >/dev/null 2>&1
    proot-distro login fedora -- /usr/local/bin/vps-start.sh boot &
fi
