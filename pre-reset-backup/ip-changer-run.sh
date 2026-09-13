#!/bin/bash
# Container-friendly runner for ip-changer (no systemd required)
# Usage: ./ip-changer-run.sh [interval_seconds] [start|stop|status|log]
INTERVAL="${1:-10}"
# allow first arg to be action
if [[ "$1" =~ ^(start|stop|status|log)$ ]]; then ACTION="$1"; INTERVAL="${2:-10}"; else ACTION="${2:-start}"; fi
PIDFILE="$HOME/.ip-changer.pid"
LOGFILE="$HOME/ip-changer.log"

case "$ACTION" in
  start)
    # ensure tor running
    if ! (exec 3<>/dev/tcp/127.0.0.1/9051) 2>/dev/null; then
      echo "[*] Starting tor..."
      mkdir -p "$HOME/tor-data"
      nohup tor -f /etc/tor/torrc > "$HOME/tor.log" 2>&1 &
      echo $! > "$HOME/tor.pid"
      sleep 3
    else
      exec 3<&-; exec 3>&- 2>/dev/null || true
    fi
    echo "[*] Starting IP rotator every ${INTERVAL}s (pidfile $PIDFILE)"
    nohup bash -c "while true; do /root/change_tor_ip.sh; sleep $INTERVAL; done" > "$LOGFILE" 2>&1 &
    echo $! > "$PIDFILE"
    echo "[OK] rotator pid $(cat $PIDFILE). Logs: ~/tor_ip_log.txt, $LOGFILE"
    ;;
  stop)
    [ -f "$PIDFILE" ] && kill "$(cat $PIDFILE)" 2>/dev/null && rm -f "$PIDFILE" && echo "[OK] rotator stopped" || echo "[!] rotator not running"
    ;;
  status)
    echo "--- tor.log (last 5) ---"; tail -n 5 "$HOME/tor.log" 2>/dev/null || echo "no tor.log"
    echo "--- tor_ip_log.txt (last 5) ---"; tail -n 5 "$HOME/tor_ip_log.txt" 2>/dev/null || echo "no ips yet (tor still bootstrapping?)"
    echo "--- rotator ---"; [ -f "$PIDFILE" ] && ps -p "$(cat $PIDFILE)" -o pid,cmd 2>&1 || echo "rotator not running"
    ;;
  log)
    tail -f "$HOME/tor_ip_log.txt" "$LOGFILE" 2>&1
    ;;
esac
