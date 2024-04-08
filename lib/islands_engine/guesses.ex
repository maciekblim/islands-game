defmodule IslandsEngie.Guesses do
    alias IslandsEngie.{Coordinate, Guesses}

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

    g = Guesses.new()

    @doc """
    ## Examples

        iex> g = IslandsEngie.Guesses.new()
        ...> {:ok, c} = IslandsEngie.Coordinate.new(1, 1)
        ...> IslandsEngie.Guesses.add(g, :hit, c)
        %IslandsEngie.Guesses{
            hits: MapSet.new([%IslandsEngie.Coordinate{row: 1, col: 1}]),
            misses: MapSet.new([])
        }

        iex> g = IslandsEngie.Guesses.new()
        ...> {:ok, c} = IslandsEngie.Coordinate.new(4, 4)
        ...> IslandsEngie.Guesses.add(g, :miss, c)
        %IslandsEngie.Guesses{
            hits: MapSet.new([]),
            misses: MapSet.new([%IslandsEngie.Coordinate{row: 4, col: 4}])
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