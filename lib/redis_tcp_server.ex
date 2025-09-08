defmodule RedisTCPServer do
  @port 6379

  def start_link(_init_arg) do
    Task.start_link(fn -> listen() end)
  end

  @doc false
  def child_spec(arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [arg]},
      type: :worker,
      restart: :permanent,
      shutdown: 5000
    }
  end

  defp listen() do
    {:ok, socket} =
      :gen_tcp.listen(@port, [:binary, packet: :line, active: false, reuseaddr: true])

    accept_loop(socket)
  end

  defp accept_loop(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    Task.start(fn -> handle_client(client) end)
    accept_loop(socket)
  end

  defp handle_client(socket) do
    recv_command(socket)
    |> IO.inspect(label: "Command received")
    |> Redis.execute()
    |> IO.inspect(label: "Result")
    |> case do
      {:error, :unknown_command} ->
        :gen_tcp.send(socket, "-ERR unknown command\r\n")

      :pong ->
        :gen_tcp.send(socket, "+PONG\r\n")

      nil ->
        :gen_tcp.send(socket, "$-1\r\n")

      value when is_binary(value) ->
        :gen_tcp.send(socket, "$#{byte_size(value)}\r\n#{value}\r\n")

      _ ->
        :gen_tcp.send(socket, "+OK\r\n")
    end

    handle_client(socket)
  end

  defp recv_command(socket), do: recv_elements_count(socket) |> recv_elements(socket)

  defp recv_elements_count(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, <<"*", value::binary>>} ->
        case Integer.parse(value) do
          {value, _} -> value
          _ -> raise "Failed to parse elements count: #{value}"
        end

      _ ->
        raise "Expected elements count, got something else"
    end
  end

  defp recv_elements(count, socket, elements \\ [])

  defp recv_elements(0, _socket, elements), do: Enum.reverse(elements)

  defp recv_elements(count, socket, elements),
    do: recv_elements(count - 1, socket, [recv_element(socket) | elements])

  defp recv_element(socket), do: recv_element_length(socket) |> recv_element_value(socket)

  defp recv_element_length(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, <<"$", value::binary>>} ->
        case Integer.parse(value) do
          {value, _} -> value
          _ -> raise "Failed to parse element length: #{value}"
        end

      _ ->
        raise "Expected element length, got something else"
    end
  end

  defp recv_element_value(-1, _socket), do: nil

  defp recv_element_value(_length, socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, <<value::binary>>} -> String.trim(value)
      _ -> raise "Expected element value, got something else"
    end
  end
end
