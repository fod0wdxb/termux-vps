#!/bin/bash
# vps-start.sh — runs INSIDE the Fedora proot container.
# Called by the Termux `vps` script. Do not run by hand unless you know why.
#
# Idempotent: safe to run again if sshd is already up.

PORT=2222
PHASE="${1:-}"

start_sshd() {
    /usr/sbin/sshd >/dev/null 2>&1
}

ensure_sshd() {
    local pid
    if [ -f /run/sshd.pid ] && pid=$(cat /run/sshd.pid 2>/dev/null) && \
       [ -n "$pid" ] && /bin/kill -0 "$pid" 2>/dev/null; then
        return 0
    fi
    start_sshd
    if [ -f /run/sshd.pid ] && pid=$(cat /run/sshd.pid 2>/dev/null) && \
       [ -n "$pid" ] && /bin/kill -0 "$pid" 2>/dev/null; then
        return 0
    fi
    return 1
}

if ! ensure_sshd; then
    echo "[FAIL] sshd could not start."
    echo "       Debug: /usr/sbin/sshd -e"
    exit 1
fi
echo "[OK] sshd running on :$PORT (pid $(cat /run/sshd.pid))"

# PHASE=boot → headless keep-alive only (from Termux:Boot autostart)
if [ "$PHASE" = "boot" ]; then
    while /bin/sleep 30; do
        ensure_sshd || echo "[WARN] sshd died; restart failed"
    done
    exit 0
fi

# interactive phase: print connection info
echo
echo "=============================================="
echo "  Phone VPS is UP"
echo "=============================================="
if ! grep -q '^root:[^!]' /etc/shadow 2>/dev/null; then
    echo "[!] No root password set. SSH login will fail."
    echo "    Fix inside Fedora: passwd root"
fi
if [ -n "${VPS_HOST:-}" ]; then
    echo "Public (anywhere; Funnel is TLS-terminated, so ssh goes over TLS):"
    echo "    ssh -o ProxyCommand='openssl s_client -connect ${VPS_HOST}:443 -quiet' root@vps"
    echo
    echo "Tailnet-only (client has Tailscale — plain ssh):"
    echo "    ssh root@${VPS_TAILNET_IP:-<tailnet-ip>}"
else
    echo "Tailscale is not fully up — LAN mode only:"
    echo "    ssh root@${VPS_LAN_IP:-<phone-lan-ip>} -p ${PORT}"
fi
echo "Password: the Fedora root password (set with 'passwd' inside Fedora)"
echo "VPS up while this Termux session runs."
echo "Stop:  Ctrl+C here, or ./vps-stop in Termux"
echo "=============================================="
echo

# interactive keep-alive
while /bin/sleep 30; do
    ensure_sshd || echo "[WARN] sshd died; restart failed"
done
