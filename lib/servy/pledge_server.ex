defmodule Servy.GenericServer do
  def start(callback_module, initial_state, name) do
    pid = spawn(__MODULE__, :listen_loop, [initial_state, callback_module])
    Process.register(pid, name)
    {:ok, pid}
  end

  def call(pid, message) do
    send(pid, {:call, self(), message})

    receive do
      {:response, response} -> response
    end
  end

  def cast(pid, message) do
    send(pid, {:cast, message})
  end

  def listen_loop(state, callback_module) do
    receive do
      {:call, sender, message} when is_pid(sender) ->
        {response, new_state} = callback_module.handle_call(message, state)
        send(sender, {:response, response})
        listen_loop(new_state, callback_module)

      {:cast, message} ->
        new_state = callback_module.handle_cast(message, state)
        listen_loop(new_state, callback_module)

      unexpected ->
        IO.inspect(unexpected)
        listen_loop(state, callback_module)
    end
  end
end

defmodule Servy.PledgeServer do
  @name :pledge_server
  alias Servy.GenericServer

  def start do
    GenericServer.start(__MODULE__, [], @name)
  end

  def handle_cast(:clear, _state) do
    []
  end

  def handle_call(:total_pledged, state) do
    total = Enum.reduce(state, 0, fn {_, amount}, acc -> acc + amount end)
    {total, state}
  end

  def handle_call(:recent_pledges, state) do
    {state, state}
  end

  def handle_call({:create_pledge, name, amount}, state) do
    {:ok, id} = send_pledge_to_external_service(name, amount)
    most_recent_pledges = Enum.take(state, 2)
    new_state = [{name, amount} | most_recent_pledges]
    {id, new_state}
  end

  def clear do
    GenericServer.cast(@name, :clear)
  end

  defp send_pledge_to_external_service(_name, _amount) do
    # Sends the pledge to the external service
    {:ok, "pledge-#{:rand.uniform(1000)}"}
  end

  def create_pledge(name, amount) do
    GenericServer.call(@name, {:crete_pledge, name, amount})
  end

  def recent_pledges() do
    GenericServer.call(@name, :recent_pledges)
  end

  def total_pledged() do
    GenericServer.call(@name, :total_pledged)
  end
end
