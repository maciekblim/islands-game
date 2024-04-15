defmodule IslandsEngine.Guesses do
    alias IslandsEngine.{Coordinate, Guesses}

    @enforce_keys [:hits, :misses]
    defstruct [:hits, :misses]

    @type t :: %__MODULE__{
        hits:  map(),
        misses:  map()
    }

    @type guess_action :: :hit | :miss

    @spec new() :: Guesses.t()
    def new(), do: %Guesses{
        hits: MapSet.new(),
        misses: MapSet.new()
    }

    @doc """
    ## Examples

        iex> g = IslandsEngine.Guesses.new()
        ...> {:ok, c} = IslandsEngine.Coordinate.new(1, 1)
        ...> IslandsEngine.Guesses.add(g, :hit, c)
        %IslandsEngine.Guesses{
            hits: MapSet.new([%IslandsEngine.Coordinate{row: 1, col: 1}]),
            misses: MapSet.new([])
        }

        iex> g = IslandsEngine.Guesses.new()
        ...> {:ok, c} = IslandsEngine.Coordinate.new(4, 4)
        ...> IslandsEngine.Guesses.add(g, :miss, c)
        %IslandsEngine.Guesses{
            hits: MapSet.new([]),
            misses: MapSet.new([%IslandsEngine.Coordinate{row: 4, col: 4}])
        }
    """

    @spec add(t(), guess_action(), Coordinate.t()) :: t()
    def add(%Guesses{} = guesses, :hit, %Coordinate{} = coordinate) do
        update_in(guesses.hits, &MapSet.put(&1, coordinate))
    end

    def add(%Guesses{} = guesses, :miss, %Coordinate{} = coordinate) do
        update_in(guesses.misses, &MapSet.put(&1, coordinate))
    end
end
