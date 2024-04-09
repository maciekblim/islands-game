defmodule IslandsEngie.Rules do
    alias __MODULE__

    defstruct state: :initialized

    @type state :: :initialized | :players_set
    @type action :: :add_player
    @type t :: %__MODULE__{
        state: state(),
    }

    @doc """
    ## Examples

        iex> IslandsEngie.Rules.new()
        %Rules{}
    """
    @spec new() :: t()
    def new(), do: %Rules{}

    @doc """
    ## Examples

        iex> rules = IslandsEngie.Rules.new()
        ...> IslandsEngie.Rules.check(rules, :add_player)
        {:ok, %IslandsEngie.Rules{state: :players_set}}

        iex> rules = IslandsEngie.Rules.new()
        ...> IslandsEngie.Rules.check(rules, :wrong_action)
        :error
    """
    @spec check(t(), action()) :: :error | {:ok, t()}
    def check(%Rules{state: :initialized} = rules, :add_player),
        do: {:ok, %Rules{rules | state: :players_set}}
    def check(_state, _action), do: :error
end