defmodule IslandsEngine.Coordinate do
    alias __MODULE__

    @enforce_keys [:row, :col]
    defstruct [:row, :col]

    @board_range 1..10


    @type t :: %__MODULE__{
        row: pos_integer,
        col: pos_integer
    }

    @type creation_result :: {:ok, t()} | {:error, any()}

    @doc """
    ## Examples

        iex> IslandsEngine.Coordinate.new(1, 1)
        {:ok, %IslandsEngine.Coordinate{row: 1, col: 1}}

        iex> IslandsEngine.Coordinate.new(-1, 1)
        {:error, :invalid_coordinate}

        iex> IslandsEngine.Coordinate.new(4, 11)
        {:error, :invalid_coordinate}
    """
    @spec new(pos_integer(), pos_integer()) :: creation_result()
    def new(row, col) when row in @board_range and col in @board_range, do:
        {:ok, %Coordinate{row: row, col: col}}
    def new(_row, _col), do: {:error, :invalid_coordinate}
end
