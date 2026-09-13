#!/data/data/com.termux/files/usr/bin/bash
# install.sh — one-shot reproducible setup. Safe to re-run any time.
# Run from the repo root in plain Termux:  bash install.sh
set -euo pipefail

DISTRO="${DISTRO:-fedora}"
PORT="${PORT:-2222}"
BORE_RELAY="${BORE_RELAY:-bore.pub}"
BORE_PORT="${BORE_PORT:-22022}"
BORE_VERSION="0.6.0"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

step() { echo; echo "=== [${1}/6] ${2} ==="; }
ok()   { echo "    [ok] $*"; }

# --- [1/6] packages ----------------------------------------------------
step 1 "Base packages"
pkg update -y
pkg install -y proot-distro openssh curl wget ifconfig 2>/dev/null || pkg install -y proot-distro openssh curl wget net-tools
ok "base packages"

# --- [2/6] Fedora container --------------------------------------------
step 2 "proot-distro: $DISTRO"
if proot-distro list 2>/dev/null | grep -qE "^\* *$DISTRO"; then
    ok "$DISTRO already installed"
else
    proot-distro install "$DISTRO"
    ok "$DISTRO installed"
fi

# --- [3/6] sshd + bore inside container --------------------------------
step 3 "sshd + bore inside $DISTRO"
if proot-distro login "$DISTRO" -- test -x /usr/local/bin/bore 2>/dev/null && \
   proot-distro login "$DISTRO" -- test -x /usr/sbin/sshd 2>/dev/null; then
    ok "sshd + bore already installed"
else
    proot-distro login "$DISTRO" -- bash << 'INNER'
    set -e
    dnf install -y openssh-server cracklib-dicts curl
    ssh-keygen -A
    if ! grep -q "^Port $PORT$" /etc/ssh/sshd_config 2>/dev/null; then
        printf '\n# --- termux-vps ---\nPort %s\nPermitRootLogin yes\nPasswordAuthentication yes\n' "$PORT" >> /etc/ssh/sshd_config
    fi
    /usr/sbin/sshd -t
INNER
    proot-distro push "$SCRIPT_DIR/vps-start.sh" /usr/local/bin/vps-start.sh >/dev/null
    proot-distro login "$DISTRO" -- bash -c '
        curl -fsSL -o /tmp/bore.tgz https://github.com/ekzhang/bore/releases/download/v0.6.0/bore-v0.6.0-aarch64-unknown-linux-musl.tar.gz
        tar xzf /tmp/bore.tgz -C /tmp
        mv /tmp/bore /usr/local/bin/bore && chmod +x /usr/local/bin/bore
        rm -f /tmp/bore.tgz
        /usr/local/bin/bore --version'
    ok "sshd (:$PORT) + bore installed in container"
fi

# --- [4/6] Termux-side scripts -----------------------------------------
step 4 "Installing scripts"
cp "$SCRIPT_DIR/vps" "$SCRIPT_DIR/vps-stop" "$HOME/"
chmod +x "$HOME/vps" "$HOME/vps-stop"
ok "~/vps, ~/vps-stop"

# --- [5/6] root password ------------------------------------------------
step 5 "Root password"
if proot-distro login "$DISTRO" -- bash -c 'grep -q "^root:[^!*]" /etc/shadow' 2>/dev/null; then
    ok "root password already set"
else
    echo
    echo "  >>> ACTION NEEDED: set the Fedora root password (your SSH password):"
    echo "  >>>   proot-distro login $DISTRO"
    echo "  >>>   passwd root"
    echo "  >>>   exit"
fi

# --- [6/6] done ----------------------------------------------------------
step 6 "Done"
echo
echo "  Start your VPS any time:   ~/vps"
echo "  It prints the public ssh command (bore.pub:$BORE_PORT if free)."
echo "  Stop it:                   ~/vps-stop"
echo
echo "Install finished."
