#!/data/data/com.termux/files/usr/bin/bash
# install.sh — one-shot reproducible setup. Safe to re-run any time.
# Run from the repo root in plain Termux:  bash install.sh
set -euo pipefail

DISTRO="${DISTRO:-fedora}"
PORT="${PORT:-2222}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

step() { echo; echo "=== [${1}/7] ${2} ==="; }
ok()   { echo "    [ok] $*"; }

# --- [1/7] packages ----------------------------------------------------
step 1 "Base packages"
pkg update -y
pkg install -y proot-distro openssh termux-services curl wget procps coreutils zstd resolv-conf ifconfig resolv-conf
command -v ifconfig >/dev/null 2>&1 || pkg install -y net-tools
ok "base packages"

# --- [2/7] tailscale-termux ---------------------------------------------
step 2 "tailscale-termux (bropines/tailscale-termux-cli)"
if command -v tailscale >/dev/null 2>&1; then
    ok "already installed: $(tailscale version 2>/dev/null | head -1 || echo present)"
else
    curl -fsSL https://raw.githubusercontent.com/bropines/tailscale-termux-cli/main/remote-install.sh | bash
    command -v tailscale >/dev/null 2>&1 && ok "tailscale-termux installed" || { echo "[FAIL] tailscale install failed"; exit 1; }
fi

# --- [3/7] Fedora container --------------------------------------------
step 3 "proot-distro: $DISTRO"
if proot-distro list 2>/dev/null | grep -qE "^\* *$DISTRO"; then
    ok "$DISTRO already installed"
else
    proot-distro install "$DISTRO"
    ok "$DISTRO installed"
fi

# --- [4/7] sshd inside container ---------------------------------------
step 4 "sshd inside $DISTRO"
if proot-distro login "$DISTRO" -- test -x /usr/sbin/sshd 2>/dev/null; then
    ok "openssh-server already installed"
else
    proot-distro login "$DISTRO" -- bash << 'INNER'
    set -e
    dnf install -y openssh-server
    ssh-keygen -A
    # config is appended once (idempotent)
    if ! grep -q "^Port $PORT$" /etc/ssh/sshd_config 2>/dev/null; then
        printf '\n# --- termux-vps ---\nPort %s\nPermitRootLogin yes\nPasswordAuthentication yes\n' "$PORT" >> /etc/ssh/sshd_config
    fi
    /usr/sbin/sshd -t
INNER
    ok "sshd configured on :$PORT"
fi

# --- [5/7] scripts ------------------------------------------------------
step 5 "Installing scripts"
proot-distro push "$SCRIPT_DIR/vps-start.sh" /usr/local/bin/vps-start.sh >/dev/null
proot-distro login "$DISTRO" -- chmod +x /usr/local/bin/vps-start.sh
cp "$SCRIPT_DIR/vps" "$SCRIPT_DIR/vps-stop" "$HOME/"
chmod +x "$HOME/vps" "$HOME/vps-stop"
mkdir -p "$HOME/termux-vps"
cp "$SCRIPT_DIR"/{vps,vps-stop,vps-start.sh,boot-autostart.sh,README.md} "$HOME/termux-vps/" 2>/dev/null || true
ok "~/vps, ~/vps-stop, ~/termux-vps/"

# --- [6/7] tailscale service + login ------------------------------------
step 6 "tailscaled service"
tailscaled-start --service=on >/dev/null 2>&1 || true
STATE="$(tailscale status --json 2>/dev/null | sed -n 's/.*"BackendState"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
case "${STATE:-}" in
    Running)
        ok "Tailscale logged in and running"
        ;;
    *)
        echo
        echo "  >>> ACTION NEEDED: Tailscale login."
        echo "  >>> Run:  tailscale up"
        echo "  >>> Open the printed URL, sign in with the SAME account you use everywhere."
        echo "  >>> Then run:  bash install.sh   (again — it is idempotent, continues from here)"
        ;;
esac

# --- [7/7] root password + funnel ---------------------------------------
step 7 "Final checks"
if proot-distro login "$DISTRO" -- bash -c 'grep -q "^root:[^!*]" /etc/shadow' 2>/dev/null; then
    ok "root password already set"
else
    echo
    echo "  >>> ACTION NEEDED: set the Fedora root password (what you'll type at SSH):"
    echo "  >>>   proot-distro login $DISTRO"
    echo "  >>>   passwd root"
    echo "  >>>   exit"
fi

echo
echo "  Funnel (public SSH from anywhere, no client software) enables on first ./vps run."
echo "  If your tailnet has never had Funnel approved, ./vps prints the approval URL once."
echo
echo "  After the steps above, start your VPS any time:"
echo "      ${HOME}/vps"
echo
echo "Install finished."
