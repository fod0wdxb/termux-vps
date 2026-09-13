# termux-vps

Turn **any** Android phone running [Termux](https://termux.dev) + proot-distro into a
mini VPS you can SSH into from anywhere — with **zero extra software on the
client machine**, thanks to [Tailscale Funnel](https://tailscale.com/kb/1223/funnel).

```
laptop ──ssh──► internet ──► Tailscale Funnel (:443) ──► sshd in Fedora proot (:2222)
```

## Quick start (fresh Termux)

Requirements:

- Android 11+ phone (the tailscale-termux package needs this)
- [Termux](https://github.com/termux/termux-app/releases) installed from GitHub Releases or
  F-Droid — **not** the Play Store build (deprecated, breaks `pkg`/`proot-distro`)
- A free [Tailscale account](https://login.tailscale.com/start) (sign in when prompted)

```bash
pkg update && pkg install -y git
git clone https://github.com/fod0wdxb/termux-vps.git
cd termux-vps
bash install.sh
```

`install.sh` is **idempotent** — safe to re-run after interruptions; it skips
what's already done. It prints the few interactive steps it can't do for you:

1. `passwd root` — inside the Fedora container (your SSH password)
2. `tailscale up` — sign in with your Tailscale account
3. Funnel approval — one URL click, first time only per tailnet

Then start the VPS any time: `~/vps`

## Daily usage

| Command | Where | What |
|---|---|---|
| `~/vps` | Termux | Boots VPS: wake-lock, tailscaled check, Funnel forwarders, sshd, prints ssh command |
| `~/vps-stop` | Termux | Full teardown: sshd, forwarders, wake-lock |
| `ssh root@<name>.ts.net -p 443` | anywhere | Log in over the public Funnel bridge |
| `ssh root@100.x.y.z` | tailnet client | Tailnet-only path (needs Tailscale on client) |

The VPS exists **only while `vps` runs** — you decide when the phone is reachable.

## Autostart on phone reboot (optional)

Install the [Termux:Boot](https://wiki.termux.com/wiki/Termux:Boot) app (F-Droid,
same signature as Termux), then once:

```bash
mkdir -p ~/.termux/boot
cp ~/termux-vps/boot-autostart.sh ~/.termux/boot/10-vps
```

After each phone reboot the VPS comes up headless (~30s), no Termux app open needed.
Battery-optimization exemption for both Termux apps recommended.

## The pieces

```
vps                  Termux orchestrator (idempotent, graceful degradation to LAN mode)
vps-start.sh         inside Fedora: starts sshd, banner, keep-alive loop
vps-stop             teardown that never kills its own ancestors
boot-autostart.sh    Termux:Boot hook for reboot survival
install.sh           one-shot idempotent installer
```

### How it works

- **sshd** runs inside the Fedora proot container on `:2222`, root + password login.
- **Termux's tailscaled** runs in userspace-networking mode (Android has no root
  VPN tunnel), so inbound connections must be bridged.
- **`tailscale funnel --tcp=443`** bridges the public internet to `127.0.0.1:2222`
  — the zero-client-software path.
- **`tailscale serve --tcp=22`** bridges the tailnet to the same sshd — if you do
  have Tailscale on a client, use this path (faster, private, still works).
- `vps` exports connection info as env vars into the container; the banner shows
  whichever paths are actually available. If Tailscale is down, it degrades to
  LAN mode instead of failing.

## Robustness notes

- Every script is **idempotent** — `vps` twice, `vps-stop` twice, `install.sh`
  after a partial run: all safe.
- `vps-start.sh` keep-alive re-checks sshd every 30s; if it dies, it restarts.
- `vps-stop` walks each target's parent chain and never kills its own ancestors.
- `vps` handles: tailscaled not running (starts it), not logged in (warns, LAN
  mode), Funnel unapproved (prints the approval URL).

## Security

- Funnel exposes **tcp/443 only** to the internet; everything else on the phone
  is unreachable. Bots do scan `.ts.net` — use a long random password or SSH keys.
- Going key-only: add your key to `/root/.ssh/authorized_keys` in Fedora, then
  set `PasswordAuthentication no` in `/etc/ssh/sshd_config`.
- `vps-stop` (or closing Termux) removes all exposure instantly.
- Never commit passwords/tokens; none are in this repo.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `vps` says LAN mode only | `tailscale up` (login), or `tailscale-test` (diagnostics) |
| ssh auth fails | `proot-distro login fedora` → `passwd root` |
| Funnel "not enabled" | `vps` prints the approval URL; open it, re-run `vps` |
| dies after minutes | hold `termux-wake-lock` (automatic), exempt Termux from battery optimization |
| after phone reboot | run `~/vps`, or set up Termux:Boot (above) |
| `tailscale up` hangs | `tailscale-test` diagnostics from the tailscale-termux package |

## Credits

- [bropines/tailscale-termux-cli](https://github.com/bropines/tailscale-termux-cli) —
  the patched Tailscale build that makes userspace-mode + Funnel work on Termux.

## License

MIT
