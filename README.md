# WanRouter

Simple NAT router for the Fairphone 2 (Nerves). It shares two upstream
internet connections — a 4G modem and a WiFi client — with downstream devices
plugged into Ethernet (`eth0`).

- **WAN — `wwan0`**: in-kernel QMI modem, driven by
  [`vintage_net_qmi`](https://github.com/mlainez/vintage_net_qmi) on top of
  [`qmi`](https://github.com/mlainez/qmi). APN is hardcoded to `simbase` in
  `config/target.exs` — change `service_providers` for other carriers.
- **WAN — `wlan0`**: WiFi client (station) that joins an upstream access point
  via DHCP. Credentials come from `config/.env.exs` (gitignored); see
  [WiFi setup](#wifi-setup). If no credentials are set, `wlan0` is left
  unconfigured and the device runs cellular-only.
- **WAN priority**: vintage_net's default route prioritization prefers WiFi
  (`wlan0`) over mobile (`wwan0`), so `wwan0` acts as failover when WiFi is down.
- **LAN — `eth0`**: static `10.0.1.42/24`. This is the gateway address LAN
  clients use. There is **no DHCP server yet** (see the TODO in
  `config/target.exs`), so clients must be configured statically — e.g. address
  `10.0.1.x/24`, gateway/DNS `10.0.1.42`.
- **NAT**: `WanRouter.WanForward` enables `ip_forward` and adds a `MASQUERADE`
  rule plus a stateful `INPUT` accept for return traffic on **both** WAN
  interfaces (`wwan0` and `wlan0`).

## Prerequisites

Host Elixir/Erlang are pinned in `.tool-versions` (Erlang `28.4.1`, Elixir
`1.19.5-otp-28`). With [asdf](https://asdf-vm.com) installed:

```sh
asdf install
```

The host Elixir and Erlang must share the same major OTP version, or Mix will
refuse to build.

## WiFi setup

To enable the `wlan0` WAN, provide the upstream network's credentials in a
gitignored env file (the passphrase never lands in git):

```sh
cp config/.env.exs.example config/.env.exs
# edit config/.env.exs and set WIFI_SSID / WIFI_PSK (WPA2/WPA3 personal)
```

Also set `regulatory_domain` in `config/target.exs` to your 2-letter country
code (e.g. `"BE"`, `"US"`) for correct WiFi channel support; it defaults to
`"00"` (world).

## Build & flash

```sh
export MIX_TARGET=nerves_system_fairphone2
mix deps.get
mix firmware
mix burn   # or flash the resulting .fw to the FP2 userdata partition
```

The target system (`Spin42/nerves_system_fairphone2`) is pinned to tag
`v1.33.8` in `mix.exs`. Nerves downloads the prebuilt artifact published on that
GitHub release rather than compiling Buildroot locally (no `nerves: [compile:
true]`). The artifact is cached under `~/.local/share/nerves/artifacts/` after
the first build.

## Test plan

- Boot the FP2 and check `VintageNet.info/0`: `wwan0` should reach `:internet`,
  and `wlan0` should associate and reach `:internet` once credentials are set.
- Pull the WiFi (or power down the AP) and confirm traffic fails over to the 4G
  uplink; restore it and confirm `wlan0` becomes the preferred route again.
- Statically configure a laptop on `eth0` (address `10.0.1.x/24`, gateway/DNS
  `10.0.1.42`) and confirm it routes external traffic out a WAN.
- `ssh ovcs-4g-gw.local` for an IEx prompt.
