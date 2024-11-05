defmodule Servy.KickStarter do
  use GenServer

  def start do
    GenServer.start(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Process.flag(:trap_exit, true)
    server_pid = spawn(Servy.HttpServer, :start, [4000])
    Process.link(server_pid)
    {:ok, server_pid}
  end

  def handle_info({:EXIT, _pid, reason}, _state) do
    IO.puts("Server died with reason: #{inspect(reason)}")
    server_pid = spawn_link(Servy.HttpServer, :start, [4000])
    {:noreply, server_pid}
  end
end
