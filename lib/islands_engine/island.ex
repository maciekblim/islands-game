defmodule IslandsEngie.Island do
    alias IslandsEngie.{Coordinate, Island}

    @enforce_keys [:coordinates, :hit_coordinates]
    defstruct [:coordinates, :hit_coordinates]

    
    @type t :: %__MODULE__{
        coordinates: map(),
        hit_coordinates: map()
    }

    @spec new() :: Island.t()
    def new(), do: %Island{
        coordinates: MapSet.new(),
        hit_coordinates: MapSet.new()
    }

end