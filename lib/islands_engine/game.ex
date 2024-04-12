defmodule IslandsEngie.Game do
    alias IslandsEngie.{Board, Guesses, Rules}

    use GenServer

    def init(name) do
        player1 = %{
            name: name,
            board: Board.new(),
            guesses: Guesses.new()
        }

        player2 = %{
            name: nil,
            board: Board.new(),
            guesses: Guesses.new()
        }

        {:ok, %{
            player1: player1,
            player2: player2,
            rules: Rules.new()
        }}
    end

    def start_link(name) when is_binary(name) do
        GenServer.start_link(__MODULE__, name, [])
    end
end