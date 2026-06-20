# Tailscale module

The `midgard.pc.tailscale` module manages Tailscale and provides a `ts` CLI command for switching between named tailnets (e.g. home, dev, prod).

## Setup

Enable the module and define your tailnets:

```nix
midgard.pc.tailscale = {
  enable = true;
  tailnets = {
    home = {
      loginServer = "https://head.example.io";
      authKeyFile = "/run/secrets/tailscale-auth-key";
    };
    dev  = { loginServer = "https://head.dev.example.io"; sshUser = "odin"; };
    prod = { loginServer = "https://head.example.io";     sshUser = "odin"; };
  };
};
```

Then switch tailnets with:

```bash
ts dev     # connect to dev tailnet via OIDC browser flow
ts prod    # connect to prod tailnet
ts home    # connect to home tailnet using pre-auth key
ts status  # show current tailscale status
```

## Options reference

### Per-tailnet options

| Option | Type | Description |
|--------|------|-------------|
| `loginServer` | `str` | Full headscale/tailscale URL. |
| `authKeyFile` | `str \| null` | Path to a pre-auth key file. If set, uses authkey; otherwise opens an OIDC browser flow. |
| `sshUser` | `str \| null` | If set, regenerates `~/.ssh/config.d/tailscale` after connecting with this user for all online peers. |
| `sshLoadKeyCommand` | `str \| null` | Command run via `Match exec` before each SSH connection to peers on this tailnet. Use to dynamically load keys into ssh-agent without storing them on disk. Requires `sshUser`. |

## SSH config generation

When `sshUser` is set, `ts <tailnet>` writes `~/.ssh/config.d/tailscale` with a `Host` block for each online peer:

```
Host huginn
  User odin

Host tor
  User odin
```

The file is **fully regenerated on every switch** — do not edit it manually.

`ts` also ensures `~/.ssh/config` has `Include config.d/*` at the top (prepending it if missing).

### Dynamic key loading (`sshLoadKeyCommand`)

Set `sshLoadKeyCommand` to a script that loads the required SSH key into `ssh-agent` on demand, without storing the key on disk:

```nix
let
  ensureAsgardKey = pkgs.writeShellScriptBin "ensure-asgard-key" ''
    if ${pkgs.openssh}/bin/ssh-add -L 2>/dev/null | grep -q "fornybar-dataflyt"; then
      exit 0
    fi
    key=$(az keyvault secret show --id "https://vault.vault.azure.net/secrets/ssh-key" \
      2>/dev/null | jq -r '.value // empty')
    [ -z "$key" ] && exit 1
    tmpfile=$(mktemp)
    trap 'rm -f "$tmpfile"' EXIT
    printf '%s\n' "$key" > "$tmpfile"
    chmod 600 "$tmpfile"
    ssh-add "$tmpfile" 2>/dev/null
  '';
in {
  midgard.pc.tailscale.tailnets.dev = {
    loginServer     = "https://head.dev.example.io";
    sshUser         = "odin";
    sshLoadKeyCommand = "${ensureAsgardKey}/bin/ensure-asgard-key";
  };
}
```

When `sshLoadKeyCommand` is set, the generated SSH config adds a `Match exec` block before the `Host` blocks:

```
Match host huginn,tor,urd exec "/nix/store/.../ensure-asgard-key"

Host huginn
  User odin
...
```

The `Match exec` fires before each connection attempt. Its exit code is ignored — the block carries no additional settings; its only purpose is the side effect of loading the key into ssh-agent. SSH then tries all agent keys as normal, which will include the freshly loaded key.

## Gotchas

### `networking.extraHosts` overrides tailscale DNS

If a host that lives on the tailnet is also listed in `networking.extraHosts`, the static entry takes precedence over tailscale's DNS. SSH will connect to the static IP (e.g. `127.0.1.1`) instead of the peer's real tailscale address, and key auth will fail against the wrong target.

**Fix:** Do not add tailnet peer hostnames to `networking.extraHosts`. Let tailscale's MagicDNS (or your headscale DNS) resolve them.

### `~/.ssh/config.d/tailscale` is overwritten on every switch

`ts <tailnet>` regenerates the file completely from the current online peer list. Any manual edits to this file are lost. Put persistent SSH config for these hosts in a separate file under `~/.ssh/config.d/`.

### `Include config.d/*` ordering matters

SSH applies the first matching `Host` block it sees. `Include config.d/*` must appear at the **top** of `~/.ssh/config` so the generated tailscale config is read before any catch-all `Host *` blocks. The `ts` command prepends the `Include` line automatically if it is missing, but check if you have an existing `~/.ssh/config` with content that may conflict.

### ssh-agent must be running for `sshLoadKeyCommand`

The `Match exec` script calls `ssh-add`. If `SSH_AUTH_SOCK` is not set or the agent socket does not exist, the key load silently fails. Ensure your login shell or desktop session starts `ssh-agent` (e.g. via `programs.ssh.startAgent = true` in home-manager or gnome-keyring).

### `--force-reauth` is used for OIDC tailnets on every switch

For tailnets without `authKeyFile`, `tailscale up --force-reauth` is passed on every `ts <tailnet>` call. This triggers a fresh authentication browser flow each time. If you switch tailnets frequently, consider using a pre-auth key (`authKeyFile`) to avoid repeated browser logins.
