# termux-vps

Turn an Android phone running [Termux](https://termux.dev) + proot-distro into a
mini VPS you can SSH into from anywhere — with **zero extra software on the
client machine**, thanks to [Tailscale Funnel](https://tailscale.com/kb/1223/funnel).

```
laptop ──ssh──► internet ──► Tailscale Funnel (:443) ──► sshd in Fedora proot (:2222)
```

## Why this exists

You want to experiment with a Linux box from your laptop, and the phone in your
pocket is the only spare hardware you have. This repo makes the whole setup a
one-command affair — and, more importantly, **reproducible**: wipe Termux, run
`install.sh`, and you're back.

## Quick start (fresh Termux)

```bash
pkg update && pkg install -y git
git clone https://github.com/fod0wdxb/termux-vps.git
cd termux-vps
bash install.sh
```

The install script prints the few interactive steps it can't do for you
(`passwd`, `tailscale up`, Funnel enable). Total hands-on time: ~5 minutes.

## Daily usage

| Command | Where | What it does |
|---|---|---|
| `./vps` | Termux | Boots the VPS: wake-lock, ensures tailscaled + Funnel are up, starts sshd in proot, prints the ssh command |
| `./vps-stop` | Termux | Kills sshd, closes the Funnel forwarder, releases the wake lock |
| `ssh root@<name>.ts.net -p 443` | anywhere | Log in (password auth) |

The VPS exists **only while `./vps` is running** — that's by design; you decide
when your phone is reachable.

## The pieces

```
vps                 (Termux ~/vps)        Orchestrator: run from plain Termux
vps-start.sh        (Fedora /usr/local/bin)  Starts sshd, prints connection info, keep-alive loop
vps-stop            (Termux ~/vps-stop)   Teardown
install.sh          (repo)                One-shot reproducible installer
```

### How it works

- **sshd** runs inside the Fedora proot container on port `2222`, with
  root + password login.
- **Termux's tailscaled** runs in userspace-networking mode (no root VPN tunnel
  on Android), so plain tailnet IPs can't receive inbound connections directly.
- **`tailscale funnel --tcp=443`** bridges the public internet to `127.0.0.1:2222`,
  which is what makes the phone SSH-able from any machine, no Tailscale client
  installed.
- `./vps` runs `vps-start.sh` inside proot in the foreground — when the
  Termux session dies, sshd dies with it. `termux-wake-lock` keeps Android
  from killing the session.

## Reproducibility notes

- Fedora 44 via `proot-distro`. Any distro works; `dnf install openssh-server`
  is the only distro-specific line in `install.sh`.
- Tailscale comes from [bropines/tailscale-termux-cli](https://github.com/bropines/tailscale-termux-cli)
  (`tailscale-termux` package) — a patched build for Termux/Android 11+, installed
  via its upstream installer. It expects `termux-services` and manages the
  daemon via `sv`.
- The Funnel hostname (`<something>.tailXXXX.ts.net`) is tied to your Tailscale
  account, not this repo — after a wipe it's the same, because the node key
  is re-registered under the same account. Your tailnet *name* stays stable.
- Funnel exposes **port 443 only, TCP** to the internet. Everything else on the
  phone is unreachable.

## Security

- Funnel means the public internet can reach your sshd. **Use a long random
  password** (20+ chars) or SSH keys. Bots do scan `.ts.net` hostnames.
- `./vps-stop` (or just closing Termux) removes all exposure instantly.
- Disable password auth entirely once you've set up key auth:
  in Fedora, set `PasswordAuthentication no` in `/etc/ssh/sshd_config`.
- Credentials inside the Fedora container are saved at `/root/VPS-CREDENTIALS.txt`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `./vps` prints LAN-mode only | tailscaled isn't up: `tailscaled-start --service=on` |
| ssh connects but auth fails | `proot-distro login fedora` → `passwd root` |
| `tailscale funnel` says "not enabled" | open the URL it prints, approve, re-run |
| sshd dies after a while | check `termux-wake-lock` held; disable battery optimization for Termux |
| `tailscale up` hangs | see `tailscale-test` (diagnostics from the tailscale-termux package) |

## Why not Tailscale on the laptop too?

If you do install the Tailscale client on your laptop, everything gets nicer:
`ssh root@100.x.y.z` (tailnet IP, port 22, tailnet-only, no public exposure).
This repo defaults to Funnel precisely so the laptop needs **nothing** —
trade-off: your sshd is publicly reachable while `./vps` runs.

## License

MIT — do whatever.
