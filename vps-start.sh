#!/bin/bash
# vps-start.sh — runs INSIDE the Fedora proot container (from Termux `vps`).
# Boots sshd + a bore tunnel to bore.pub with a FIXED public port.
# Idempotent: sshd is only (re)started if not running.

PORT=2222                # local sshd port inside the container
BORE_RELAY="${BORE_RELAY:-bore.pub}"
BORE_PORT="${BORE_PORT:-22022}"   # fixed public port on the relay
PHASE="${1:-}"

# NOTE: in proot, sshd runs fine but never writes /run/sshd.pid, and /proc is
# unreliable for name matching. The only trustworthy liveness test is the port.
ssh_listening() {
    python3 -c "import socket; s=socket.socket(); s.settimeout(2); exit(0 if s.connect_ex(('127.0.0.1', $PORT)) == 0 else 1)" 2>/dev/null
}

ensure_sshd() {
    ssh_listening && return 0
    /usr/sbin/sshd >/dev/null 2>&1
    sleep 1
    ssh_listening
}

ensure_bore() {
    # already running? (match the binary; refresh the port file if missing)
    if pgrep -x bore >/dev/null 2>&1; then
        [ -s /tmp/bore_port ] || sed 's/\x1b\[[0-9;]*m//g' /tmp/bore.log 2>/dev/null | grep -oE 'bore\.pub:[0-9]+' | grep -oE '[0-9]+' | head -1 > /tmp/bore_port
        return 0
    fi
    # bore.pub assigns ports from its own pool; --port is a *request* only.
    # Ask for the last-known-good port (sticky across restarts), else the default.
    WANT="$BORE_PORT"
    [ -s /tmp/bore_port ] && WANT="$(cat /tmp/bore_port)"
    nohup bore local "$PORT" --to "$BORE_RELAY" --port "$WANT" > /tmp/bore.log 2>&1 &
    sleep 3
    if pgrep -x bore >/dev/null 2>&1; then
        GOT="$(sed 's/\x1b\[[0-9;]*m//g' /tmp/bore.log | grep -oE 'bore\.pub:[0-9]+' | grep -oE '[0-9]+' | head -1)"
        echo "${GOT:-$WANT}" > /tmp/bore_port
        BORE_PORT="$(cat /tmp/bore_port)"
        return 0
    fi
    return 1
}

if ! ensure_sshd; then
    echo "[FAIL] sshd could not start. Debug: /usr/sbin/sshd -e"
    exit 1
fi
echo "[OK] sshd listening on :$PORT"

if ensure_bore; then
    # always re-read the CURRENT port (bore.pub may assign a different one
    # than requested — the log line is the truth, the file may be stale)
    BORE_FINAL="$(sed 's/\x1b\[[0-9;]*m//g' /tmp/bore.log 2>/dev/null | grep -oE 'bore\.pub:[0-9]+' | grep -oE '[0-9]+' | head -1)"
    [ -n "$BORE_FINAL" ] && echo "$BORE_FINAL" > /tmp/bore_port
    [ -z "$BORE_FINAL" ] && BORE_FINAL="$(cat /tmp/bore_port 2>/dev/null)"
    echo "[OK] bore tunnel up: bore.pub:$BORE_FINAL -> :$PORT"
else
    echo "[!] bore tunnel failed (relay down or unreachable). LAN mode only."
    BORE_FINAL=""
fi

# PHASE=boot → headless keep-alive only (Termux:Boot autostart)
if [ "$PHASE" = "boot" ]; then
    while /bin/sleep 30; do
        ensure_sshd   || echo "[WARN] sshd died; restart failed"
        ensure_bore   || echo "[WARN] bore died; restart failed"
    done
    exit 0
fi

# interactive banner
echo
echo "=============================================="
echo "  Phone VPS is UP"
echo "=============================================="
if ! grep -q '^root:[^!]' /etc/shadow 2>/dev/null; then
    echo "[!] No root password set. SSH login will fail."
    echo "    Fix inside Fedora: passwd root"
fi
if [ -n "$BORE_FINAL" ]; then
    echo "Public (anywhere, plain ssh):"
    echo "    ssh root@bore.pub -p ${BORE_FINAL}"
fi
LAN_IP="${VPS_LAN_IP:-}"
if [ -n "$LAN_IP" ]; then
    echo "LAN (same Wi-Fi/hotspot):"
    echo "    ssh root@${LAN_IP} -p ${PORT}"
fi
echo
echo "Password: the Fedora root password (set with 'passwd' inside Fedora)"
echo "VPS up while this Termux session runs."
echo "Stop:  Ctrl+C here, or ./vps-stop in Termux"
echo "=============================================="
echo

# interactive keep-alive with watchdog
while /bin/sleep 30; do
    ensure_sshd || echo "[WARN] sshd died; restart failed"
    ensure_bore || echo "[WARN] bore died; restart failed"
done
