defmodule IslandsEngine.GameSupervisor do
  # TODO check DynamicSupervisor https://hexdocs.pm/elixir/1.13/DynamicSupervisor.html
  use Supervisor

  alias IslandsEngine.Game

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Supervisor.init([Game], strategy: :simple_one_for_one)
  end

  def start_game(name) do
    Supervisor.start_child(__MODULE__, [name])
  end

  def stop_game(name) do
    Supervisor.terminate_child(__MODULE__, pid_from_name(name))
  end

  defp pid_from_name(name) do
    name
    |> Game.via_tuple()
    |> GenServer.whereis()
  end
end

# defmodule IslandsEngine.GameSupervisor do
#   use DynamicSupervisor

#   alias IslandsEngine.Game

#   def start_link() do
#     DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
#   end

#   def start_child() do
#     spec = {Game, []}
#     DynamicSupervisor.start_child(__MODULE__, spec)
#   end

#   def init(:ok) do
#     DynamicSupervisor.init(
#       strategy: :one_for_one
#     )
#   end
# end
