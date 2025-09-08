defmodule RedisSupervisor do
  use Supervisor

  def start_link(init_arg), do: Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)

  @impl true
  def init(_init_arg) do
    Supervisor.init(
      [
        {Redis, %{}},
        {RedisTCPServer, []}
      ],
      strategy: :one_for_one
    )
  end
end
