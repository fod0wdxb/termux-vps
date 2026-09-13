#!/bin/bash
# ip-changer: rotate Tor exit IP via ControlPort NEWNYM
# Works with and without `nc` (falls back to bash /dev/tcp).

set -u
LOG_FILE="${HOME:-/root}/tor_ip_log.txt"

# Auto-detect Tor control auth cookie (distro paths differ)
find_cookie() {
    for p in \
        "/run/tor/control.authcookie" \
        "/var/run/tor/control.authcookie" \
        "${HOME:-/root}/tor-data/control_auth_cookie" \
        "/var/lib/tor/control_auth_cookie" \
        "/var/lib/tor/control.authcookie"; do
        if [ -f "$p" ]; then echo "$p"; return 0; fi
    done
    return 1
}

COOKIE_FILE="$(find_cookie || true)"
if [ -z "${COOKIE_FILE:-}" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: control.authcookie not found (is tor running?)" | tee -a "$LOG_FILE" >&2
    exit 1
fi

COOKIE=$(xxd -ps "$COOKIE_FILE" 2>/dev/null | tr -d '\n')
if [ -z "${COOKIE:-}" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: could not read cookie from $COOKIE_FILE" | tee -a "$LOG_FILE" >&2
    exit 1
fi

# Send NEWNYM: prefer nc/ncat if present, else bash /dev/tcp (no extra deps)
send_newnym() {
    if command -v nc >/dev/null 2>&1; then
        printf 'AUTHENTICATE %s\r\nSIGNAL NEWNYM\r\nQUIT\r\n' "$COOKIE" | nc 127.0.0.1 9051 > /dev/null
    elif command -v ncat >/dev/null 2>&1; then
        printf 'AUTHENTICATE %s\r\nSIGNAL NEWNYM\r\nQUIT\r\n' "$COOKIE" | ncat 127.0.0.1 9051 > /dev/null
    else
        exec 3<>/dev/tcp/127.0.0.1/9051 || { echo "ERROR: cannot connect to Tor ControlPort 9051" >&2; return 1; }
        printf 'AUTHENTICATE %s\r\nSIGNAL NEWNYM\r\nQUIT\r\n' "$COOKIE" >&3
        cat <&3 > /dev/null 2>&1 &
        sleep 1
        exec 3<&-; exec 3>&- || true
    fi
}

send_newnym

# Store IP logs
IP=$(curl -s --max-time 20 --socks5-hostname 127.0.0.1:9050 https://check.torproject.org/api/ip 2>/dev/null | jq -r .IP 2>/dev/null)
if [ -z "${IP:-}" ] || [ "$IP" = "null" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: NEWNYM sent but could not fetch exit IP" | tee -a "$LOG_FILE"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - New Tor IP: $IP" | tee -a "$LOG_FILE"
fi
