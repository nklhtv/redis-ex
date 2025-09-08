defmodule Redis do
  use GenServer

  @vsn "0.1.0"

  def start_link(initial_data \\ %{}),
    do: GenServer.start_link(__MODULE__, initial_data, name: __MODULE__)

  def execute(["PING"]), do: GenServer.call(__MODULE__, :ping)

  def execute(["SET", key, value]), do: GenServer.cast(__MODULE__, {:set, key, value})

  def execute(["GET", key]), do: GenServer.call(__MODULE__, {:get, key})

  def execute(["EXPIRE", key, seconds]), do: GenServer.cast(__MODULE__, {:expire, key, seconds})

  def execute(["PERSIST", key]), do: GenServer.cast(__MODULE__, {:persist, key})

  def execute(_command), do: {:error, :unknown_command}

  @impl true
  def init(initial_data) do
    {:ok, %{data: initial_data, timers: %{}}}
  end

  @impl true
  def handle_call(:ping, _from, state), do: {:reply, :pong, state}

  @impl true
  def handle_call({:get, key}, _from, state) when is_binary(key) do
    value = state.data |> Map.get(key, nil)
    {:reply, value, state}
  end

  @impl true
  def handle_call(request, _from, state), do: {:reply, {:error, :unknown_call, request}, state}

  @impl true
  def handle_cast({:set, key, value}, state) when is_binary(key) and is_binary(value) do
    next_state = %{state | data: state.data |> Map.put(key, value)}
    {:noreply, next_state}
  end

  @impl true
  def handle_cast({:set, key, value}, state) when is_binary(key) and is_number(value) do
    next_state = %{state | data: state.data |> Map.put(key, to_string(value))}
    {:noreply, next_state}
  end

  @impl true
  def handle_cast({:expire, key, seconds}, state)
      when is_binary(key) and is_integer(seconds) and seconds >= 0 do
    if state.timers[key], do: Process.cancel_timer(state.timers[key])
    timer = Process.send_after(self(), {:key_expired, key}, seconds * 1_000)
    next_state = %{state | timers: state.timers |> Map.put(key, timer)}
    {:noreply, next_state}
  end

  @impl true
  def handle_cast({:persist, key}, state) when is_binary(key) do
    if state.timers[key], do: Process.cancel_timer(state.timers[key])
    next_state = %{state | timers: state.timers |> Map.delete(key)}
    {:noreply, next_state}
  end

  @impl true
  def handle_cast(_unknown, state), do: {:noreply, state}

  @impl true
  def handle_info({:key_expired, key}, state) when is_binary(key) do
    next_state = %{
      state
      | timers: state.timers |> Map.delete(key),
        data: state.data |> Map.delete(key)
    }

    {:noreply, next_state}
  end

  @impl true
  def handle_info(_unknown, state), do: {:noreply, state}
end
