defmodule Neuron do
  use GenServer

  defstruct [:activator, :threshold, :value]

  # API
  def start_link(activator, threshold, value) do
    {:ok, pid} = GenServer.start_link(__MODULE__, [activator, threshold, value])
  end

  def activate(neuron, signal) do
    neuron |> GenServer.cast({:activate, signal})
  end

  def create(last_layer? \\ false) do
    {:ok, pid} = start_link(&(&1 * :random.uniform), (if last_layer?, do: random_letter, else: :random.uniform), random_letter)
    pid
  end

  # Callbacks
  def init([activator, threshold, value]) do
    {:ok, %Neuron{activator: activator, threshold: threshold, value: value}}
  end

  def handle_cast({:activate, signal}, %Neuron{activator: activator, threshold: threshold, value: value} = state) do
    new_value = signal |> activator.()
    new_state =
      if !threshold || (new_value >= threshold) do
        NeuralNetwork.activated(self(), new_value)
        %{state|value: new_value}
      else
        state
      end
    {:noreply, new_state}
  end

  # Helpersa
  def random_float do
    :random.uniform
  end

  def random_letter do
    a_code = ?a
    number_of_letters = ?z - a_code + 1
    letter_number = :random.uniform(number_of_letters)
    letter_code = a_code + letter_number - 1
    letter_code
  end

end
