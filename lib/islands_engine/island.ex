defmodule IslandsEngine.Island do
    alias IslandsEngine.{Coordinate, Island}

    @enforce_keys [:coordinates, :hit_coordinates]
    defstruct [:coordinates, :hit_coordinates]


    @type t :: %__MODULE__{
        coordinates: map(),
        hit_coordinates: map()
    }

    @type island_type :: :square | :atoll | :dot | :l_shape | :s_shape

    @type creation_result :: {:ok, t()} | {:error, any()}
    @type guess_result :: {:hit, t()} | :miss

    @doc """
    ## Examples

        iex> {:ok, c} = IslandsEngine.Coordinate.new(4, 4)
        ...> Island.new(:l_shape, c)
        {:ok,
         %IslandsEngine.Island{
            coordinates: MapSet.new([
                %IslandsEngine.Coordinate{row: 4, col: 4},
                %IslandsEngine.Coordinate{row: 5, col: 4},
                %IslandsEngine.Coordinate{row: 6, col: 4},
                %IslandsEngine.Coordinate{row: 6, col: 5}
            ]),
            hit_coordinates: MapSet.new([])
        }}

        iex> {:ok, c} = IslandsEngine.Coordinate.new(4, 4)
        ...> IslandsEngine.Island.new(:wrong, c)
        {:error, :invalid_island_type}

        iex> {:ok, c} = IslandsEngine.Coordinate.new(10, 10)
        ...> IslandsEngine.Island.new(:l_shape, c)
        {:error, :invalid_coordinate}
    """
    @spec new(island_type(), Coordinate.t()) :: creation_result()
    def new(type, %Coordinate{} = upper_left) do
        with {:ok, offsets} <- offsets(type),
             %MapSet{} = coordinates <- add_coordinates(offsets, upper_left)
        do
            {:ok, %Island{coordinates: coordinates, hit_coordinates: MapSet.new()}}
        else
            error -> error
        end
    end

    defp offsets(:square), do: {:ok, [{0, 0}, {0, 1}, {1, 0}, {1, 1}]}
    defp offsets(:atoll), do: {:ok, [{0, 0}, {0, 1}, {1, 1}, {2, 0}, {2, 1}]}
    defp offsets(:dot), do: {:ok, [{0, 0}]}
    defp offsets(:l_shape), do: {:ok, [{0, 0}, {1, 0}, {2, 0}, {2, 1}]}
    defp offsets(:s_shape), do: {:ok, [{0, 1}, {0, 2}, {1, 0}, {1, 1}]}
    defp offsets(_), do: {:error, :invalid_island_type}

    defp add_coordinates(offsets, upper_left) do
        Enum.reduce_while(offsets, MapSet.new(), fn offset, acc ->
            add_coordinate(acc, upper_left, offset)
        end)
    end

    defp add_coordinate(coordinates, %Coordinate{row: row, col: col}, {row_offset, col_offset}) do
        case Coordinate.new(row + row_offset, col + col_offset) do
            {:ok, coordinate} -> {:cont, MapSet.put(coordinates, coordinate)}
            {:error, :invalid_coordinate} -> {:halt, {:error, :invalid_coordinate}}
        end
    end

    @doc """
    ## Examples

        iex> {:ok, square_coordinate} = IslandsEngine.Coordinate.new(1, 1)
        ...> {:ok, square} = IslandsEngine.Island.new(:square, square_coordinate)
        ...> {:ok, dot_coordinate} = IslandsEngine.Coordinate.new(1, 2)
        ...> {:ok, dot} = IslandsEngine.Island.new(:dot, dot_coordinate)
        ...> IslandsEngine.Island.overlaps?(square, dot)
        true

        iex> {:ok, square_coordinate} = IslandsEngine.Coordinate.new(1, 1)
        ...> {:ok, square} = IslandsEngine.Island.new(:square, square_coordinate)
        ...> {:ok, l_shape_coordinate} = IslandsEngine.Coordinate.new(5, 5)
        ...> {:ok, l_shape} = IslandsEngine.Island.new(:l_shape, l_shape_coordinate)
        ...> IslandsEngine.Island.overlaps?(square, l_shape)
        false
    """
    @spec overlaps?(t(), t()) :: boolean()
    def overlaps?(existing_island, new_island) do
        not(MapSet.disjoint?(existing_island.coordinates, new_island.coordinates))
    end

    @doc """
    ## Examples

        iex> {:ok, square_coordinate} = IslandsEngine.Coordinate.new(1, 1)
        ...> {:ok, square} = IslandsEngine.Island.new(:square, square_coordinate)
        ...> {:ok, miss} = IslandsEngine.Coordinate.new(5, 5)
        ...> IslandsEngine.Island.guess(square, miss)
        :miss

        iex> {:ok, square_coordinate} = IslandsEngine.Coordinate.new(1, 1)
        ...> {:ok, square} = IslandsEngine.Island.new(:square, square_coordinate)
        ...> {:ok, hit} = IslandsEngine.Coordinate.new(2, 2)
        ...> IslandsEngine.Island.guess(square, hit)
        {:hit,
         %IslandsEngine.Island{
            coordinates: MapSet.new([
                %IslandsEngine.Coordinate{row: 1, col: 1},
                %IslandsEngine.Coordinate{row: 2, col: 1},
                %IslandsEngine.Coordinate{row: 1, col: 2},
                %IslandsEngine.Coordinate{row: 2, col: 2}
            ]),
            hit_coordinates: MapSet.new([%IslandsEngine.Coordinate{row: 2, col: 2}])
        }}
    """
    @spec guess(t(), Coordinate.t()) :: guess_result()
    def guess(island, coordinate) do
        case MapSet.member?(island.coordinates, coordinate) do
            true -> hit_coordinates = MapSet.put(island.hit_coordinates, coordinate)
                    {:hit, %Island{island | hit_coordinates: hit_coordinates}}
            false -> :miss
        end
    end

    @doc """
    ## Examples

        iex> {:ok, dot_coordinate} = IslandsEngine.Coordinate.new(4, 4)
        ...> {:ok, dot} = IslandsEngine.Island.new(:dot, dot_coordinate)
        ...> {:hit, dot} = IslandsEngine.Island.guess(dot, dot_coordinate)
        ...> IslandsEngine.Island.forested?(dot)
        true

        iex> {:ok, dot_coordinate} = IslandsEngine.Coordinate.new(4, 4)
        ...> {:ok, dot} = IslandsEngine.Island.new(:dot, dot_coordinate)
        ...> IslandsEngine.Island.forested?(dot)
        false
    """
    @spec forested?(t()) :: boolean()
    def forested?(island), do: MapSet.equal?(island.coordinates, island.hit_coordinates)

    @spec types() :: list(island_type())
    def types(), do: [:atoll, :dot, :l_shape, :s_shape, :square]
end
