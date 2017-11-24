defmodule Neuron do
  use GenServer

  defstruct [:activator, :threshold, :value, :is_immutable]

  # API
  def start_link(activator, threshold, value, is_immutable?) do
    {:ok, pid} = GenServer.start_link(__MODULE__, [activator, threshold, value, is_immutable?])
  end

  def activate(neuron, signal) do
    neuron |> GenServer.cast({:activate, signal})
  end

  def clear_value(neuron) do
    neuron |> GenServer.cast(:clear_value)
  end

  def create(last_layer? \\ false, number \\ nil) do
    {:ok, pid} = start_link(&(&1 |> sigmoid()), (if last_layer?, do: 0.5), (if last_layer?, do: random_letter, else: :random.uniform), last_layer?)
    pid
  end

  # Callbacks
  def init([activator, threshold, value, is_immutable?]) do
    {:ok, %Neuron{activator: activator, threshold: threshold, value: value, is_immutable: is_immutable?}}
  end

  def handle_cast({:activate, signal}, %Neuron{activator: activator, threshold: threshold, value: value, is_immutable: is_immutable?} = state) do
    new_value = (signal + (value |> decay())) |> activator.()
    new_state =
      if !threshold || (new_value >= threshold) do
        NeuralNetwork.activated(self(), (if is_immutable?, do: value, else: new_value))
        if is_immutable? do
          state
        else
          %{state|value: new_value}
        end
      else
        state
      end
    {:noreply, new_state}
  end

  def handle_cast(:clear_value, %Neuron{is_immutable: is_immutable?} = state) do
    NeuralNetwork.clear_completed(self())
    {:noreply, (if is_immutable?, do: state, else: %{state|value: nil})}
  end

  # Helpersa
  def random_float do
    :random.uniform
  end

  def random_letter(offset \\ nil) do
    a_code = ?a
    if offset do
      a_code + offset - 1
    else
      number_of_letters = ?z - a_code + 1
      letter_number = :random.uniform(number_of_letters)
      letter_code = a_code + letter_number - 1
      letter_code
    end
    # number_of_letters = ?z - a_code + 1
    # letter_number = :random.uniform(number_of_letters)
    # letter_code = a_code + letter_number - 1
    # letter_code
  end

  def sigmoid(x) do
    1.0 / (1 + :math.exp(-x))
  end

  def decay(x) do
    :math.exp(-x)
  end

end
