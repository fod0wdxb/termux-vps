#!/data/data/com.termux/files/usr/bin/bash
# boot-autostart.sh — for the Termux:Boot app (phone restart survival).
# Install once:  cp termux-vps/boot-autostart.sh ~/.termux/boot/10-vps

if [ -x "$HOME/vps" ]; then
    nohup "$HOME/vps" >/dev/null 2>&1 &
else
    termux-wake-lock
    proot-distro login fedora -- /usr/local/bin/vps-start.sh boot &
fi
