defmodule LetterFreqCollector do
  use GenServer

  defstruct [:freq]

  def start_link(freqs \\ nil) do
    __MODULE__ |> GenServer.start_link([freqs || %{}], name: LetterFreqCollector)
  end

  def flush do
    __MODULE__ |> GenServer.cast(:flush)
  end

  def collect(letter) do
    __MODULE__ |> GenServer.cast({:collect, letter})
  end

  def get_values do
    get_freqs()
  end

  def get_freqs do
    __MODULE__ |> GenServer.call(:get_freqs)
  end

  def init([freqs]) do
    {:ok, %LetterFreqCollector{freq: freqs}}
  end

  def handle_cast(:flush, state) do
    {:noreply, %{state|freq: %{}}}
  end

  def handle_cast({:collect, letter}, %LetterFreqCollector{freq: freqs} = state) do
    {:noreply, freqs |> Map.update(letter, 1, fn value -> value + 1 end)}
  end

  def handle_call(:get_freqs, _from, %LetterFreqCollector{freq: freqs} = state) do
    all_freqs = ?a..?z
      |> Enum.map(fn code ->
        freqs[code]
      end)
    {:reply, all_freqs, state}
  end
end
