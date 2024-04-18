defmodule IslandsEngine.Game do
    alias IslandsEngine.{Board, Coordinate, Guesses, Island, Rules}

    use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient

    @players [:player1, :player2]

    @timeout_ms 1000 * 60 * 60 * 24

    def via_tuple(name), do: {:via, Registry, {Registry.Game, name}}

    def start_link(name) when is_binary(name) do
        GenServer.start_link(__MODULE__, name, name: via_tuple(name))
    end

    def init(name) do
        send(self(), {:set_state, name})
        {:ok, fresh_state(name)}
    end

    def handle_info(:timeout, state) do
        {:stop, {:shutdown, :timeout}, state}
    end

    def handle_info({:set_state, name}, _state) do
        state =
            case lookup_state(name) do
              nil -> fresh_state(name)
              state -> state
            end
        persist_state(state)
        {:noreply, state, @timeout_ms}
    end

    def terminate({:shutdown, :timeout}, state) do
        :ets.delete(:game_state, state.player1.name)
    end

    def terminate(_reason, _state), do: :ok

    def handle_call({:add_player, name}, _from, state) do
        with {:ok, rules} <- Rules.check(state.rules, :add_player) do
            state
            |> update_player2_name(name)
            |> update_rules(rules)
            |> reply_success(:ok)
        else
            :error -> reply_error(state, :error)
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
            :error -> reply_error(state, :error)
            {:error, :invalid_coordinate} -> reply_error(state, {:error, :invalid_coordinate})
            {:error, :invalid_island_type} -> reply_error(state, {:error, :invalid_island_type})
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
            :error -> reply_error(state, :error)
            false -> reply_error(state, {:error, :not_all_islands_positioned})
        end
    end

    def handle_call({:guess_coordinate, player, row, col}, _from, state) do
        oponent_player = opponent(player)
        opponent_board = player_board(state, oponent_player)

        with {:ok, rules} <- Rules.check(state.rules, {:guess_coordinate, player}),
             {:ok, coordinate} <- Coordinate.new(row, col),
             {hit_or_miss, forested_island, win_status, opponent_board} <- Board.guess(opponent_board, coordinate),
             {:ok, rules} <- Rules.check(rules, {:win_check, win_status})
        do
            state
            |> update_board(oponent_player, opponent_board)
            |> update_guesses(player, hit_or_miss, coordinate)
            |> update_rules(rules)
            |> reply_success({hit_or_miss, forested_island, win_status})
        else
            :error -> reply_error(state, :error)
            {:error, :invalid_coordinate} -> reply_error(state, {:error, :invalid_coordinate})
        end
    end

    @doc """
    ## Examples

        iex> {:ok, game} = IslandsEngine.Game.start_link("Frank")
        ...> IslandsEngine.Game.add_player(game, "Jon")
        :ok
    """
    def add_player(game, name) when is_binary(name) do
        GenServer.call(game, {:add_player, name})
    end

    @doc """
    ## Examples

        iex> {:ok, game} = IslandsEngine.Game.start_link("Frank")
        ...> IslandsEngine.Game.add_player(game, "Wilma")
        ...> IslandsEngine.Game.position_island(game, :player1, :square, 1, 1)
        :ok

        iex> {:ok, game} = IslandsEngine.Game.start_link("Frank")
        ...> IslandsEngine.Game.add_player(game, "Wilma")
        ...> IslandsEngine.Game.position_island(game, :player1, :square, 12, 1)
        {:error, :invalid_coordinate}

        iex> {:ok, game} = IslandsEngine.Game.start_link("Frank")
        ...> IslandsEngine.Game.add_player(game, "Wilma")
        ...> IslandsEngine.Game.position_island(game, :player1, :wrong_type, 12, 1)
        {:error, :invalid_island_type}
    """
    def position_island(game, player, island_type, row, col) when player in @players do
        GenServer.call(game, {:position_island, player, island_type, row, col})
    end

    @doc """
    ## Examples

        iex> {:ok, game} = IslandsEngine.Game.start_link("Dino")
        ...> IslandsEngine.Game.add_player(game, "Pebbles")
        ...> IslandsEngine.Game.set_islands(game, :player1)
        {:error, :not_all_islands_positioned}

        iex> {:ok, game} = IslandsEngine.Game.start_link("Dino")
        ...> IslandsEngine.Game.add_player(game, "Pebbles")
        ...> IslandsEngine.Game.position_island(game, :player1, :atoll, 1, 1)
        ...> IslandsEngine.Game.position_island(game, :player1, :dot, 1, 4)
        ...> IslandsEngine.Game.position_island(game, :player1, :l_shape, 1, 5)
        ...> IslandsEngine.Game.position_island(game, :player1, :s_shape, 5, 1)
        ...> IslandsEngine.Game.position_island(game, :player1, :square, 5, 5)
        ...> IslandsEngine.Game.set_islands(game, :player1)
        {:ok, _}
    """
    def set_islands(game, player) when player in @players do
        GenServer.call(game, {:set_islands, player})
    end

    @doc """
    ## Examples

        iex> {:ok, game} = IslandsEngine.Game.start_link("Miles")
        ...> IslandsEngine.Game.add_player(game, "Trane")
        ...> IslandsEngine.Game.guess_coordinate(game, :player1, 1, 1)
        :error
    """
    def guess_coordinate(game, player, row, col) when player in @players do
        GenServer.call(game, {:guess_coordinate, player, row, col})
    end

    defp update_player2_name(state, name),
        do: put_in(state.player2.name, name)

    defp update_rules(state, rules),
        do: %{state | rules: rules}

    defp update_board(state, player, board),
        do: Map.update!(state, player, fn player -> %{player | board: board} end)

    defp update_guesses(state, player, hit_or_miss, coordinate) do
        update_in(state[player].guesses, fn guesses ->
           Guesses.add(guesses,hit_or_miss, coordinate)
        end)
    end

    defp reply_success(state, reply) do
        persist_state(state)
        {:reply, reply, state, @timeout_ms}
    end

    defp reply_error(state, error),
        do: {:reply, error, state, @timeout_ms}

    defp player_board(state, player),
        do: Map.get(state, player).board

    defp opponent(:player1), do: :player2
    defp opponent(:player2), do: :player1

    defp fresh_state(name) do
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

        %{
            player1: player1,
            player2: player2,
            rules: Rules.new()
        }
    end

    defp persist_state(state) do
        :ets.insert(:game_state, {state.player1.name, state})
    end

    defp lookup_state(name) do
        case :ets.lookup(:game_state, name) do
            [] -> nil
            [{_, state}] -> state
        end
    end
end
