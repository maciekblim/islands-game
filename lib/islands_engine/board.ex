defmodule IslandsEngine.Board do
    alias IslandsEngine.{Coordinate, Island}

    @type t :: map()

    @type guess_result :: {:hit | :miss, Island.type() | :none, :win | :no_win, t()}

    @doc """
    ## Examples

        iex> board = IslandsEngine.Board.new()
        %{}
    """
    @spec new() :: t()
    def new(), do: %{}

    @doc """
    ## Examples

        iex> board = IslandsEngine.Board.new()
        ...> {:ok, square_coordinate} = IslandsEngine.Coordinate.new(1, 1)
        ...> {:ok, square} = IslandsEngine.Island.new(:square, square_coordinate)
        ...> board = IslandsEngine.Board.position_island(board, :square, square)
        ...> {:ok, dot_coordinate} = IslandsEngine.Coordinate.new(2, 2)
        ...> {:ok, dot} = IslandsEngine.Island.new(:dot, dot_coordinate)
        ...> IslandsEngine.Board.position_island(board, :dot, dot)
        {:error, :overlappin_island}

        iex> board = IslandsEngine.Board.new()
        ...> {:ok, square_coordinate} = IslandsEngine.Coordinate.new(1, 1)
        ...> {:ok, square} = IslandsEngine.Island.new(:square, square_coordinate)
        ...> board = IslandsEngine.Board.position_island(board, :square, square)
        ...> {:ok, dot_coordinate} = IslandsEngine.Coordinate.new(3, 3)
        ...> {:ok, dot} = IslandsEngine.Island.new(:dot, dot_coordinate)
        ...> IslandsEngine.Board.position_island(board, :dot, dot)
        %{
            dot: %IslandsEngine.Island{
                coordinates: MapSet.new([%IslandsEngine.Coordinate{row: 3, col: 3}]),
                hit_coordinates: MapSet.new([])
            },
            square: %IslandsEngine.Island{
                coordinates: MapSet.new([
                %IslandsEngine.Coordinate{row: 1, col: 1},
                %IslandsEngine.Coordinate{row: 2, col: 1},
                %IslandsEngine.Coordinate{row: 1, col: 2},
                %IslandsEngine.Coordinate{row: 2, col: 2}
                ]),
                hit_coordinates: MapSet.new([])
            }
        }
    """
    @spec position_island(t(), Island.island_type(), Island.t()) :: t()
    def position_island(board, key, %Island{} = island) do
        case overlaps_exisiting_island?(board, key, island) do
            true -> {:error, :overlappin_island}
            false -> Map.put(board, key, island)
        end
    end

    defp overlaps_exisiting_island?(board, new_key, new_island) do
        Enum.any?(board, fn {key, island} ->
            key != new_key and Island.overlaps?(island, new_island)
        end)
    end

    @spec all_islands_positioned?(t()) :: boolean()
    def all_islands_positioned?(board), do: Enum.all?(Island.types(), &(Map.has_key?(board, &1)))

        @doc """
    ## Examples

        iex> board = IslandsEngine.Board.new()
        ...> {:ok, square_coordinate} = IslandsEngine.Coordinate.new(1, 1)
        ...> {:ok, square} = IslandsEngine.Island.new(:square, square_coordinate)
        ...> board = IslandsEngine.Board.position_island(board, :square, square)
        ...> {:ok, dot_coordinate} = IslandsEngine.Coordinate.new(3, 3)
        ...> {:ok, dot} = IslandsEngine.Island.new(:dot, dot_coordinate)
        ...> board = IslandsEngine.Board.position_island(board, :dot, dot)
        ...> {:ok, miss_coordinate} = IslandsEngine.Coordinate.new(10, 10)
        ...> IslandsEngine.Board.guess(board, miss_coordinate)
        {:miss, :none, :no_win, %{
            dot: %IslandsEngine.Island{
                coordinates: MapSet.new([%IslandsEngine.Coordinate{row: 3, col: 3}]),
                hit_coordinates: MapSet.new([])
            },
            square: %IslandsEngine.Island{
                coordinates: MapSet.new([
                %IslandsEngine.Coordinate{row: 1, col: 1},
                %IslandsEngine.Coordinate{row: 2, col: 1},
                %IslandsEngine.Coordinate{row: 1, col: 2},
                %IslandsEngine.Coordinate{row: 2, col: 2}
                ]),
                hit_coordinates: MapSet.new([])
            }
        }}

        iex> board = IslandsEngine.Board.new()
        ...> {:ok, square_coordinate} = IslandsEngine.Coordinate.new(1, 1)
        ...> {:ok, square} = IslandsEngine.Island.new(:square, square_coordinate)
        ...> board = IslandsEngine.Board.position_island(board, :square, square)
        ...> {:ok, dot_coordinate} = IslandsEngine.Coordinate.new(3, 3)
        ...> {:ok, dot} = IslandsEngine.Island.new(:dot, dot_coordinate)
        ...> board = IslandsEngine.Board.position_island(board, :dot, dot)
        ...> {:ok, hit_coordinate} = IslandsEngine.Coordinate.new(1, 1)
        ...> IslandsEngine.Board.guess(board, hit_coordinate)
        {:hit, :square, :no_win, %{
            dot: %IslandsEngine.Island{
                coordinates: MapSet.new([%IslandsEngine.Coordinate{row: 3, col: 3}]),
                hit_coordinates: MapSet.new([])
            },
            square: %IslandsEngine.Island{
                coordinates: MapSet.new([
                %IslandsEngine.Coordinate{row: 1, col: 1},
                %IslandsEngine.Coordinate{row: 2, col: 1},
                %IslandsEngine.Coordinate{row: 1, col: 2},
                %IslandsEngine.Coordinate{row: 2, col: 2}
                ]),
                hit_coordinates: MapSet.new([])
            }
        }}

        iex> board = IslandsEngine.Board.new()
        ...> {:ok, dot_coordinate} = IslandsEngine.Coordinate.new(3, 3)
        ...> {:ok, dot} = IslandsEngine.Island.new(:dot, dot_coordinate)
        ...> board = IslandsEngine.Board.position_island(board, :dot, dot)
        ...> {:ok, hit_coordinate} = IslandsEngine.Coordinate.new(3, 31)
        ...> IslandsEngine.Board.guess(board, hit_coordinate)
        {:hit, :dot, :win, %{
            dot: %IslandsEngine.Island{
                coordinates: MapSet.new([%IslandsEngine.Coordinate{row: 3, col: 3}]),
                hit_coordinates: MapSet.new([%IslandsEngine.Coordinate{row: 3, col: 3}])
            }
        }}
    """
    @spec guess(t(), Coordinate.t()) :: guess_result()
    def guess(board, %Coordinate{} = coordinate) do
        board
        |> check_all_islands(coordinate)
        |> guess_response(board)
    end

    defp check_all_islands(board, %Coordinate{} = coordinate) do
        Enum.find_value(board, :miss, fn {key, island} ->
            case Island.guess(island, coordinate) do
                {:hit, island} -> {key, island}
                :miss -> false
            end
        end)
    end

    defp guess_response({key, island}, board) do
        board = %{board | key => island}
        {:hit, forest_check(board, key), win_check(board), board}
    end

    defp guess_response(:miss, board) do
        {:miss, :none, :no_win, board}
    end

    defp forest_check(board, key) do
        case forested?(board, key) do
            true -> key
            false -> :none
        end
    end

    defp forested?(board, key) do
        board
        |> Map.fetch!(key)
        |> Island.forested?()
    end

    defp win_check(board) do
        case all_forested?(board) do
            true -> :win
            false -> :no_win
        end
    end

    defp all_forested?(board) do
        Enum.all?(board, fn {_, island} ->
            Island.forested?(island)
        end)
    end
end
