defmodule IslandsEngie.Island do
    alias IslandsEngie.{Coordinate, Island}

    @enforce_keys [:coordinates, :hit_coordinates]
    defstruct [:coordinates, :hit_coordinates]

    
    @type t :: %__MODULE__{
        coordinates: map(),
        hit_coordinates: map()
    }

    @type island_type :: :square | :atoll | :dot | :l_shape | :s_shape

    @type creation_result :: {:ok, t()} | {:error, any()}

    @doc """
    ## Examples

        iex> {:ok, c} = IslandsEngie.Coordinate.new(4, 4)
        ...> Island.new(:l_shape, c)
        {:ok,                                         
         %IslandsEngie.Island{                        
            coordinates: MapSet.new([                  
                %IslandsEngie.Coordinate{row: 4, col: 4},
                %IslandsEngie.Coordinate{row: 5, col: 4},
                %IslandsEngie.Coordinate{row: 6, col: 4},
                %IslandsEngie.Coordinate{row: 6, col: 5} 
            ]),                                        
            hit_coordinates: MapSet.new([])            
        }}                                           

        iex> {:ok, c} = IslandsEngie.Coordinate.new(4, 4)
        ...> IslandsEngie.Island.new(:wrong, c)
        {:error, :ivalid_island_type}

        iex> {:ok, c} = IslandsEngie.Coordinate.new(10, 10)
        ...> IslandsEngie.Island.new(:l_shape, c)
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
    defp offsets(_), do: {:error, :ivalid_island_type}

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
end