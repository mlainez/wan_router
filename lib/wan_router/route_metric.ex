defmodule WanRouter.RouteMetric do
  @moduledoc """
  Custom vintage_net default-route prioritization.

  Guarantees that WiFi (`wlan0`) outranks the 4G modem (`wwan0`) at every
  connectivity tier, so cellular is only ever used as a failover — independent
  of vintage_net's built-in defaults (which could change across upgrades).

  Ordering is still internet-before-LAN: if the WiFi access point itself loses
  its upstream, traffic falls over to 4G rather than blackholing through a
  WiFi link that can't actually reach the internet.

  Lower metric = higher priority. Wired up in `config/target.exs` via:

      config :vintage_net, route_metric_fun: {WanRouter.RouteMetric, :compute, 2}
  """
  alias VintageNet.Route.InterfaceInfo

  @spec compute(VintageNet.ifname(), InterfaceInfo.t()) :: VintageNet.Route.metric() | :disabled
  def compute(_ifname, %InterfaceInfo{status: :disconnected}), do: :disabled

  def compute("wlan0", %InterfaceInfo{status: :internet}), do: 10
  def compute("wwan0", %InterfaceInfo{status: :internet}), do: 20
  def compute("wlan0", %InterfaceInfo{status: :lan}), do: 30
  def compute("wwan0", %InterfaceInfo{status: :lan}), do: 40

  # Anything else (e.g. eth0, usb0): defer to vintage_net's built-in logic.
  def compute(ifname, info), do: VintageNet.Route.DefaultMetric.compute_metric(ifname, info)
end
