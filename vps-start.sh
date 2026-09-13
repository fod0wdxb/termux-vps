#!/bin/bash
# vps-start.sh — runs INSIDE the Fedora proot (launched by the Termux `vps` command)
# Keeps the session alive; sshd dies if the proot session exits.

PORT=2222
PHONE_IP="${1:-}"
PW="o515cNwgn4kSBCm85Rzd"

start_sshd() {
    /usr/sbin/sshd >/dev/null 2>&1
}

ensure_sshd() {
    if [ -f /run/sshd.pid ] && /bin/kill -0 "$(cat /run/sshd.pid)" 2>/dev/null; then
        return 0
    fi
    start_sshd
    if [ -f /run/sshd.pid ] && /bin/kill -0 "$(cat /run/sshd.pid)" 2>/dev/null; then
        return 0
    fi
    return 1
}

if ensure_sshd; then
    echo "[OK] SSH server is running (port $PORT)"
else
    echo "[FAIL] sshd could not start. Run: /usr/sbin/sshd -e"
    exit 1
fi

echo
echo "=============================================="
echo "  Your phone is now a mini VPS"
echo "=============================================="
if [ -n "$PHONE_IP" ]; then
    echo "From your laptop (works from ANYWHERE, no Tailscale needed):"
    echo "    ssh root@tailscale-termux.tail175840.ts.net -p 443"
    echo
    echo "Password: $PW (also saved in /root/VPS-CREDENTIALS.txt)"
else
    echo "Tailscale is not up — LAN mode only."
    echo "Find phone IP via 'ifconfig wlan0' in Termux, then:"
    echo "    ssh root@<phone-ip> -p ${PORT}"
fi
echo
echo "Password: the root password you set in Fedora (passwd command)"
echo
echo "VPS stays alive while this Termux session runs."
echo "Press Ctrl+C here to stop it."
echo "=============================================="
echo

# Keep-alive: hold the session open and restart sshd if it ever dies
while /bin/sleep 30; do
    ensure_sshd || echo "[WARN] sshd died, restart failed"
done
