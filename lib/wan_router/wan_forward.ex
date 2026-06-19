defmodule WanRouter.WanForward do
  use GenServer

  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    Task.start(fn -> run_setup_commands() end)
    {:ok, %{}}
  end

  # Upstream (WAN) interfaces. LAN clients on eth0 are NAT'd out whichever of
  # these the kernel routes the traffic to (vintage_net manages the default
  # route priority). Masquerading per output interface works regardless of
  # which WAN is currently the default route.
  @wan_interfaces ["wwan0", "wlan0"]

  defp run_setup_commands do
    Logger.info("Running boot setup commands")
    run("sysctl -w net.ipv4.ip_forward=1")

    for wan <- @wan_interfaces do
      run("iptables -t nat -A POSTROUTING -o #{wan} -j MASQUERADE")
      run("iptables -A INPUT -i #{wan} -m state --state RELATED,ESTABLISHED -j ACCEPT")
    end
  end

  defp run(cmd) do
    Logger.info("Running: #{cmd}")
    {output, status} = System.cmd("sh", ["-c", cmd], stderr_to_stdout: true)
    Logger.info("Command output: #{output}")
    status
  end
end
