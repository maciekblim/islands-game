defmodule IslandsEngie.Guesses do
    alias __MODULE__

    @enforce_keys [:hits, :misses]
    defstruct [:hits, :misses]

    @type t :: %__MODULE__{
        hits:  map(),
        misses:  map()
    }

    @spec new() :: Guesses.t()
    def new(), do: %Guesses{
        hits: MapSet.new(),
        misses: MapSet.new()
    }
end