# WanRouter

Simple NAT router that bridges a 4G uplink (`wwan0`, in-kernel QMI modem on the
Fairphone 2) to downstream Ethernet clients (`eth0`).

- **WAN**: `wwan0`, driven by [`vintage_net_qmi`](https://github.com/mlainez/vintage_net_qmi)
  on top of [`qmi`](https://github.com/mlainez/qmi). APN is hardcoded to `simbase`
  in `config/target.exs` — change `service_providers` for other carriers.
- **LAN**: `eth0`, static `10.0.3.1/24`, with an inline DHCP server
  (`one_dhcpd`, piloted by VintageNet via the `:dhcpd` key) handing out
  `10.0.3.10`–`10.0.3.100` and pointing clients at the gateway for DNS.
- **NAT**: `WanRouter.WanForward` enables `ip_forward` and adds
  `MASQUERADE` on the WAN interface plus a stateful `INPUT` accept for
  return traffic.

## Build & flash

```sh
export MIX_TARGET=nerves_system_fairphone2
mix deps.get
mix firmware
mix burn   # or flash the resulting .fw to the FP2 userdata partition
```

The target system (`Spin42/nerves_system_fairphone2`) is pinned to its `main`
branch; switch to a tagged release once one is cut.

## Test plan

- Boot the FP2, confirm `wwan0` reaches `:internet` connectivity in
  `VintageNet.info/0`.
- Plug a laptop into the FP2's USB-Ethernet adapter (or a hub) — it should
  receive an IP in `10.0.3.10`–`10.0.3.100` and route external traffic via
  the 4G uplink.
- `ssh ovcs-4g-gw.local` for an IEx prompt.
