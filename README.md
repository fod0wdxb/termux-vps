# termux-vps

Turn **any** Android phone running [Termux](https://termux.dev) + proot-distro into a
mini VPS you can SSH into from anywhere — with **zero extra software on the
client machine**, thanks to [bore](https://github.com/ekzhang/bore) (open source,
Rust, ~400 lines) and its public relay `bore.pub`.

```
laptop ──plain ssh──► bore.pub:22022 ──tunnel──► bore (phone) ──► sshd in Fedora proot (:2222)
```

Plain `ssh`. No TLS wrappers, no accounts, no client installs, no Funnel.

## Quick start (fresh Termux)

Requirements:

- Android phone, aarch64 (most phones)
- [Termux](https://github.com/termux/termux-app/releases) from GitHub Releases or
  F-Droid — **not** the Play Store build (deprecated)
- Nothing else. No accounts anywhere.

```bash
pkg update && pkg install -y git
git clone https://github.com/fod0wdxb/termux-vps.git
cd termux-vps
bash install.sh
```

One interactive step only: set the root password (`passwd root` inside Fedora).

Then start it: `~/vps` — prints the public ssh command.

## Daily usage

| Command | Where | What |
|---|---|---|
| `~/vps` | Termux | Boots VPS: wake-lock, sshd + bore tunnel with watchdog, prints ssh command |
| `~/vps-stop` | Termux | Full teardown: sshd, bore, wake-lock |
| `ssh root@bore.pub -p 22022` | anywhere | The public path — plain ssh, nothing installed |
| `ssh root@<phone-ip> -p 2222` | same Wi-Fi/hotspot | LAN path — even simpler, no relay |

The VPS exists **only while `vps` runs** — you decide when the phone is reachable.

## How it works

- **sshd** runs inside the Fedora proot container on `:2222`.
- **bore** runs inside the same container and dials *out* to `bore.pub` (no
  inbound firewall rules needed — perfect for CGNAT/mobile networks), asking
  for a **fixed public port** (`22022` by default, configurable via `BORE_PORT`).
- The laptop connects with completely ordinary ssh. SSH is end-to-end
  encrypted; the relay only shuttles bytes. bore itself is MIT-licensed and
  trivially self-hostable if you ever want your own relay: `bore server`.

### Why bore instead of Tailscale Funnel?

- Funnel requires **TLS** on port 443 (SNI routing) — plain `ssh` gets
  instantly closed, forcing an `openssl s_client` ProxyCommand hack.
- Termux's tailscaled must run userspace-mode, adding another moving piece
  that occasionally needs babysitting.
- bore is one static binary, raw TCP, one command. `ssh root@bore.pub -p N`.

## Autostart on phone reboot (optional)

Install the [Termux:Boot](https://wiki.termux.com/wiki/Termux:Boot) app (F-Droid,
same signature as Termux), then once:

```bash
mkdir -p ~/.termux/boot
cp boot-autostart.sh ~/.termux/boot/10-vps
```

The VPS comes back headless ~30s after each reboot. Exempt Termux from battery
optimization.

## Robustness notes

- All scripts are **idempotent** — safe to re-run, re-boot, stack `vps` twice.
- `vps-start.sh` watchdogs sshd **and** the bore tunnel every 30s; either is
  restarted if it dies. If the fixed relay port is taken, it falls back to a
  random port and prints the actual one.
- `vps` degrades to LAN-only mode if the relay is unreachable.
- `vps-stop` never kills its own ancestor processes.

## Security

- The public endpoint is `bore.pub` on a **fixed port** — bots do scan relays.
  Use a long random root password (20+ chars) or SSH keys.
- Key-only hardening: drop your public key into
  `/root/.ssh/authorized_keys` in Fedora, then set
  `PasswordAuthentication no` in `/etc/ssh/sshd_config`.
- `vps-stop` (or closing Termux) removes all exposure instantly.
- `bore.pub` is a free community relay — best-effort availability. For
  guaranteed uptime, self-host: run `bore server` on any $4 VPS and set
  `BORE_RELAY` in the scripts.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `bore.pub` unreachable | relay down (rare) — use LAN mode meanwhile, or self-host `bore server` |
| fixed port 22022 taken | script auto-falls back to a random port; or set your own `BORE_PORT` |
| ssh auth fails | `proot-distro login fedora` → `passwd root` |
| dies after minutes | exempt Termux from battery optimization; keep `vps` session in foreground |
| after phone reboot | `~/vps`, or set up Termux:Boot (above) |

## Credits

- [ekzhang/bore](https://github.com/ekzhang/bore) — the tunnel.
- [proot-distro](https://github.com/termux/proot-distro) — the container.

## License

MIT
