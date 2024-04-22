defmodule IslandsEngine.GamesRepository do
  @table :game_state

  def new() do
    :ets.new(@table, [:public, :named_table])
  end

  def insert(state) do
    :ets.insert(@table, {state.player1.name, state})
  end

  def delete(name) do
    :ets.delete(@table, name)
  end

  def find_by_name(name) do
    case :ets.lookup(@table, name) do
      [] -> nil
      [{_, state}] -> state
    end
  end

  def find_all() do
    :ets.tab2list(@table)
  end

  def find_all_names() do
    Enum.map(find_all(), fn {name, _state} -> name end)
  end
end
