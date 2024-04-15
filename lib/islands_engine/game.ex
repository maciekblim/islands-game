defmodule IslandsEngie.Game do
    alias IslandsEngie.{Board, Coordinate, Guesses, Island, Rules}

    use GenServer

    @players [:player1, :player2]

    def init(name) do
        player1 = %{
            name: name,
            board: Board.new(),
            guesses: Guesses.new()
        }

        player2 = %{
            name: nil,
            board: Board.new(),
            guesses: Guesses.new()
        }

        {:ok, %{
            player1: player1,
            player2: player2,
            rules: Rules.new()
        }}
    end

    def handle_call({:add_player, name}, _from, state) do
        with {:ok, rules} <- Rules.check(state.rules, :add_player) do
            state
            |> update_player2_name(name)
            |> update_rules(rules)
            |> reply_success(:ok)
        else
            :error -> {:reply, :error, state}
        end
    end

    def handle_call({:position_island, player, island_type, row, col}, _from, state) do
        board = player_board(state, player)
        with {:ok, rules} <- Rules.check(state.rules, {:position_islands, player}),
             {:ok, coordinate} <- Coordinate.new(row, col),
             {:ok, island} <- Island.new(island_type, coordinate),
             %{} = board <- Board.position_island(board, island_type, island)
        do
            state
            |> update_board(player, board)
            |> update_rules(rules)
            |> reply_success(:ok)
        else
            :error -> {:reply, :error, state}
            {:error, :invalid_coordinate} -> {:reply, {:error, :invalid_coordinate}, state}
            {:error, :invalid_island_type} -> {:reply, {:error, :invalid_island_type}, state}
        end
    end

    def handle_call({:set_islands, player}, _from, state) do
        board = player_board(state, player)
        with {:ok, rules} <- Rules.check(state.rules, {:set_islands, player}),
             true <- Board.all_islands_positioned?(board)
        do
            state
            |> update_rules(rules)
            |> reply_success({:ok, board})
        else
            :error -> {:reply, :error, state}
            false -> {:reply, {:error, :not_all_islands_positioned}, state}
        end
    end

    def start_link(name) when is_binary(name) do
        GenServer.start_link(__MODULE__, name, [])
    end

    @doc """
    ## Examples

        iex> {:ok, game} = IslandsEngie.Game.start_link("Frank")
        ...> IslandsEngie.Game.add_player(game, "Jon")
        :ok
    """
    def add_player(game, name) when is_binary(name) do
        GenServer.call(game, {:add_player, name})
    end

    @doc """
    ## Examples

        iex> {:ok, game} = IslandsEngie.Game.start_link("Frank")
        ...> IslandsEngie.Game.add_player(game, "Wilma")
        ...> IslandsEngie.Game.position_island(game, :player1, :square, 1, 1)
        :ok

        iex> {:ok, game} = IslandsEngie.Game.start_link("Frank")
        ...> IslandsEngie.Game.add_player(game, "Wilma")
        ...> IslandsEngie.Game.position_island(game, :player1, :square, 12, 1)
        {:error, :invalid_coordinate}

        iex> {:ok, game} = IslandsEngie.Game.start_link("Frank")
        ...> IslandsEngie.Game.add_player(game, "Wilma")
        ...> IslandsEngie.Game.position_island(game, :player1, :wrong_type, 12, 1)
        {:error, :invalid_island_type}
    """
    def position_island(game, player, island_type, row, col) when player in @players do
        GenServer.call(game, {:position_island, player, island_type, row, col})
    end

    @doc """
    ## Examples

        iex> {:ok, game} = IslandsEngie.Game.start_link("Dino")
        ...> IslandsEngie.Game.add_player(game, "Pebbles")
        ...> IslandsEngie.Game.set_islands(game, :player1)
        {:error, :not_all_islands_positioned}

        iex> {:ok, game} = IslandsEngie.Game.start_link("Dino")
        ...> IslandsEngie.Game.add_player(game, "Pebbles")
        ...> IslandsEngie.Game.position_island(game, :player1, :atoll, 1, 1)
        ...> IslandsEngie.Game.position_island(game, :player1, :dot, 1, 4)
        ...> IslandsEngie.Game.position_island(game, :player1, :l_shape, 1, 5)
        ...> IslandsEngie.Game.position_island(game, :player1, :s_shape, 5, 1)
        ...> IslandsEngie.Game.position_island(game, :player1, :square, 5, 5)
        ...> IslandsEngie.Game.set_islands(game, :player1)
        {:ok, _}
    """
    def set_islands(game, player) when player in @players do
        GenServer.call(game, {:set_islands, player})
    end

    defp update_player2_name(state, name),
        do: put_in(state.player2.name, name)

    defp update_rules(state, rules),
        do: %{state | rules: rules}

    defp update_board(state, player, board),
        do: Map.update!(state, player, fn player -> %{player | board: board} end)

    defp reply_success(state, reply),
        do: {:reply, reply, state}

    defp player_board(state, player),
        do: Map.get(state, player).board
end
