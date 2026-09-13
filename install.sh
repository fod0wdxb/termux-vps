#!/data/data/com.termux/files/usr/bin/bash
# install.sh — full setup for a fresh Termux install.
# Run from the repo root in plain Termux:   bash install.sh
set -euo pipefail

DISTRO="${DISTRO:-fedora}"
PORT="${PORT:-2222}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== [1/6] Installing packages ==="
pkg update -y
pkg install -y proot-distro openssh termux-services curl wget procps coreutils zstd resolv-conf

echo "=== [2/6] Installing tailscale-termux (bropines/tailscale-termux-cli) ==="
# Not in the official repos; upstream install script:
curl -fsSL https://raw.githubusercontent.com/bropines/tailscale-termux-cli/main/install.sh | bash

echo "=== [3/6] Installing Fedora container ==="
proot-distro list | grep -q "^\* $DISTRO" || proot-distro install "$DISTRO"

echo "=== [4/6] Installing scripts into Fedora container ==="
proot-distro login "$DISTRO" -- bash -s << 'INNER'
dnf install -y openssh-server
ssh-keygen -A
cat >> /etc/ssh/sshd_config << 'CONF'
Port 2222
PermitRootLogin yes
PasswordAuthentication yes
CONF
/usr/sbin/sshd -t
mkdir -p /usr/local/bin
INNER
proot-distro push "$SCRIPT_DIR/vps-start.sh" /usr/local/bin/vps-start.sh
proot-distro login "$DISTRO" -- chmod +x /usr/local/bin/vps-start.sh

echo "=== [5/6] Installing Termux-side scripts ==="
cp "$SCRIPT_DIR/vps" "$SCRIPT_DIR/vps-stop" "$HOME/"
chmod +x "$HOME/vps" "$HOME/vps-stop"

echo "=== [6/6] Next steps (must be done by you) ==="
cat << 'EOF'

1. Set a root password for Fedora:
       proot-distro login fedora
       passwd root
       exit

2. Enable tailscaled auto-start + log in to Tailscale:
       tailscaled-start --service=on
       tailscale up
   (opens a login link; use the same account on all devices)

3. Enable Funnel once (one-time, per tailnet):
       tailscale funnel --bg --tcp=443 tcp://127.0.0.1:2222
   If told "Funnel is not enabled", open the URL it prints, then re-run.

4. Start your VPS any time:
       ./vps

Then from any machine on the internet:
       ssh root@<your-tailnet-name>.ts.net -p 443

EOF
echo "Install done."
