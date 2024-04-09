defmodule IslandsEngie.Board do
    alias IslandsEngie.{Coordinate, Island}

    @type t :: map()

    @type guess_result :: :win #TODO

    @doc """
    ## Examples

        iex> board = IslandsEngie.Board.new()
        %{}
    """
    @spec new() :: t()
    def new(), do: %{}

    @doc """
    ## Examples

        iex> board = IslandsEngie.Board.new()
        ...> {:ok, square_coordinate} = IslandsEngie.Coordinate.new(1, 1)
        ...> {:ok, square} = IslandsEngie.Island.new(:square, square_coordinate)
        ...> board = IslandsEngie.Board.position_island(board, :square, square)
        ...> {:ok, dot_coordinate} = IslandsEngie.Coordinate.new(2, 2)
        ...> {:ok, dot} = IslandsEngie.Island.new(:dot, dot_coordinate)
        ...> IslandsEngie.Board.position_island(board, :dot, dot)
        {:error, :overlappin_island}

        iex> board = IslandsEngie.Board.new()
        ...> {:ok, square_coordinate} = IslandsEngie.Coordinate.new(1, 1)
        ...> {:ok, square} = IslandsEngie.Island.new(:square, square_coordinate)
        ...> board = IslandsEngie.Board.position_island(board, :square, square)
        ...> {:ok, dot_coordinate} = IslandsEngie.Coordinate.new(3, 3)
        ...> {:ok, dot} = IslandsEngie.Island.new(:dot, dot_coordinate)
        ...> IslandsEngie.Board.position_island(board, :dot, dot)
        %{
            dot: %IslandsEngie.Island{
                coordinates: MapSet.new([%IslandsEngie.Coordinate{row: 3, col: 3}]),
                hit_coordinates: MapSet.new([])
            },
            square: %IslandsEngie.Island{
                coordinates: MapSet.new([
                %IslandsEngie.Coordinate{row: 1, col: 1},
                %IslandsEngie.Coordinate{row: 2, col: 1},
                %IslandsEngie.Coordinate{row: 1, col: 2},
                %IslandsEngie.Coordinate{row: 2, col: 2}
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

        iex> board = IslandsEngie.Board.new()
        ...> {:ok, square_coordinate} = IslandsEngie.Coordinate.new(1, 1)
        ...> {:ok, square} = IslandsEngie.Island.new(:square, square_coordinate)
        ...> board = IslandsEngie.Board.position_island(board, :square, square)
        ...> {:ok, dot_coordinate} = IslandsEngie.Coordinate.new(3, 3)
        ...> {:ok, dot} = IslandsEngie.Island.new(:dot, dot_coordinate)
        ...> board = IslandsEngie.Board.position_island(board, :dot, dot)
        ...> {:ok, miss_coordinate} = IslandsEngie.Coordinate.new(10, 10)
        ...> IslandsEngie.Board.guess(board, miss_coordinate)
        {:miss, :none, :no_win, %{
            dot: %IslandsEngie.Island{
                coordinates: MapSet.new([%IslandsEngie.Coordinate{row: 3, col: 3}]),
                hit_coordinates: MapSet.new([])
            },
            square: %IslandsEngie.Island{
                coordinates: MapSet.new([
                %IslandsEngie.Coordinate{row: 1, col: 1},
                %IslandsEngie.Coordinate{row: 2, col: 1},
                %IslandsEngie.Coordinate{row: 1, col: 2},
                %IslandsEngie.Coordinate{row: 2, col: 2}
                ]),
                hit_coordinates: MapSet.new([])
            }
        }}

        iex> board = IslandsEngie.Board.new()
        ...> {:ok, square_coordinate} = IslandsEngie.Coordinate.new(1, 1)
        ...> {:ok, square} = IslandsEngie.Island.new(:square, square_coordinate)
        ...> board = IslandsEngie.Board.position_island(board, :square, square)
        ...> {:ok, dot_coordinate} = IslandsEngie.Coordinate.new(3, 3)
        ...> {:ok, dot} = IslandsEngie.Island.new(:dot, dot_coordinate)
        ...> board = IslandsEngie.Board.position_island(board, :dot, dot)
        ...> {:ok, hit_coordinate} = IslandsEngie.Coordinate.new(1, 1)
        ...> IslandsEngie.Board.guess(board, hit_coordinate)
        {:hit, :square, :no_win, %{
            dot: %IslandsEngie.Island{
                coordinates: MapSet.new([%IslandsEngie.Coordinate{row: 3, col: 3}]),
                hit_coordinates: MapSet.new([])
            },
            square: %IslandsEngie.Island{
                coordinates: MapSet.new([
                %IslandsEngie.Coordinate{row: 1, col: 1},
                %IslandsEngie.Coordinate{row: 2, col: 1},
                %IslandsEngie.Coordinate{row: 1, col: 2},
                %IslandsEngie.Coordinate{row: 2, col: 2}
                ]),
                hit_coordinates: MapSet.new([])
            }
        }}

        iex> board = IslandsEngie.Board.new()
        ...> {:ok, dot_coordinate} = IslandsEngie.Coordinate.new(3, 3)
        ...> {:ok, dot} = IslandsEngie.Island.new(:dot, dot_coordinate)
        ...> board = IslandsEngie.Board.position_island(board, :dot, dot)
        ...> {:ok, hit_coordinate} = IslandsEngie.Coordinate.new(3, 31)
        ...> IslandsEngie.Board.guess(board, hit_coordinate)
        {:hit, :dot, :win, %{
            dot: %IslandsEngie.Island{
                coordinates: MapSet.new([%IslandsEngie.Coordinate{row: 3, col: 3}]),
                hit_coordinates: MapSet.new([%IslandsEngie.Coordinate{row: 3, col: 3}])
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