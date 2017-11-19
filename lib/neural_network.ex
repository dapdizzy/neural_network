defmodule NeuralNetwork do
  @moduledoc """
  Documentation for NeuralNetwork.
  """

  use GenServer

  defstruct [:level_neurons, :neuron_level, :weights, :levels]

  # API
  def start_link(levels) do
    GenServer.start_link(__MODULE__, [levels], name: __MODULE__)
  end

  def activated(neuron, value) do
    __MODULE__ |> GenServer.cast({:activated, neuron, value})
  end

  # Callbacks
  def init([levels]) do # levels is a list of numbers of neurons to be created on corresponding level (number of item in the list)
    number_of_levels = levels |> Enum.count
    {layers_plus_one, layer_neurons, neuron_layer} =
      levels
      |> Enum.reduce({1, %{}, %{}}, fn neurons_on_layer, {layer, layer_neurons_map, neurom_layer_map} ->
        neurons = 1..neurons_on_layer
          |> Enum.map(fn _ ->
            Neuron.create(layer == number_of_levels)
          end)
        {layer + 1, layer_neurons_map |> Map.put(layer, neurons), neurons |> Enum.reduce(neurons_on_layer, fn neuron, map -> map |> Map.put(neuron, layer) end)}
      end)
    # Assign the weights for relations between neurons of sibling layers
    {_, weights} =
      layer_neurons
      |> Enum.reduce({1, %{}}, fn neurons, {layer, weights_map} ->
        new_weights_map =
          if layer < number_of_levels do
            sibling_neurons = layer_neurons[layer + 1]
            neurons |> Enum.reduce(weights_map, fn neuron, w_map ->
              weights_list = sibling_neurons
                |> Enum.map(fn _sibling_neuron ->
                  rand_weight
                end)
              w_map |> Map.put(neuron, weights_list)
            end)
          else
            weights_map
          end
        {layer + 1, new_weights_map}
      end)
    {:ok, %NeuralNetwork{level_neurons: layer_neurons, neuron_level: neuron_layer, weights: weights, levels: number_of_levels}}
  end

  def handle_cast({:activated, neuron, value}, %NeuralNetwork{level_neurons: level_neurons_map, neuron_level: neuron_level_map, weights: weights_map, levels: levels} = state) do
    neuron_level = neuron_level_map[neuron]
    if neuron_level < levels do
      weights = weights_map[neuron] # list of tuples {weight, neuron}
      weights
        |> Enum.each(fn {weight, next_neuron} ->
          next_neuron |> Neuron.activate(value * weight) # value * weight is the signal sent to the next layer neuron
        end)
    else
      OutputCollector.collect(value)
    end
    {:noreply, state}
  end

  @doc """
  Hello world.

  ## Examples

      iex> NeuralNetwork.hello
      :world

  """
  def hello do
    :world
  end

  # Helpers
  defp rand_weight(from \\ 0.5, to \\ 1.5) do
    diff = to - from
    weight = from + :random.uniform * (diff / 1.0)
    weight
  end
end
