defmodule NeuralNetwork do
  @moduledoc """
  Documentation for NeuralNetwork.
  """

  use GenServer

  defstruct [:level_neurons, :neuron_level, :weights, :levels, :clear_neurons_map, :stuff]

  # API
  def start_link(levels) do
    GenServer.start_link(__MODULE__, [levels], name: __MODULE__)
  end

  def activated(neuron, value) do
    __MODULE__ |> GenServer.cast({:activated, neuron, value})
  end

  def process(value) do
    __MODULE__ |> GenServer.cast({:process, value})
  end

  def clear_completed(neuron) do
    __MODULE__ |> GenServer.cast({:clear_completed, neuron})
  end

  def clear_values do
    __MODULE__ |> GenServer.cast(:clear_values)
  end

  def process_sentense(sentense) do
    __MODULE__ |> GenServer.cast({:process_sentense, sentense})
  end

  def feed_word(word) do
    word |> word_to_codepoint_list()
      |> Enum.each(fn {codepoint} ->
        codepoint |> NeuralNetwork.process()
      end)
  end

  # Callbacks
  def init([levels]) do # levels is a list of numbers of neurons to be created on corresponding level (number of item in the list)
    number_of_levels = levels |> Enum.count
    {layers_plus_one, layer_neurons, neuron_layer} =
      levels
      |> Enum.reduce({1, %{}, %{}}, fn neurons_on_layer, {layer, layer_neurons_map, neuron_layer_map} ->
        neurons = 1..neurons_on_layer
          |> Enum.map(fn number ->
            Neuron.create(layer == number_of_levels, number)
          end)
        {layer + 1, layer_neurons_map |> Map.put(layer, neurons), neurons |> Enum.reduce(neuron_layer_map, fn neuron, map -> map |> Map.put(neuron, layer) end)}
      end)
    # Assign the weights for relations between neurons of sibling layers
    {_, weights} =
      layer_neurons |> Enum.sort(fn {k1, _v1}, {k2, _v2} -> k1 <= k2 end)
      |> Enum.reduce({1, %{}}, fn {_layer, neurons}, {layer, weights_map} ->
        new_weights_map =
          if layer < number_of_levels do
            sibling_neurons = layer_neurons[layer + 1]
            neurons |> Enum.reduce(weights_map, fn neuron, w_map ->
              weights_list = sibling_neurons
                |> Enum.map(fn sibling_neuron ->
                  {rand_weight, sibling_neuron}
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

  def handle_cast({:process, value}, %NeuralNetwork{level_neurons: level_neurons} = state) do
    level_neurons[1]
      |> Enum.each(fn neuron ->
        neuron |> Neuron.activate(value)
      end)
    {:noreply, state}
  end

  def handle_cast({:clear_completed, neuron}, %NeuralNetwork{neuron_level: neural_level_map, level_neurons: level_neurons_map, levels: levels, weights: weights_map, stuff: completed_neurons_map} = state) do
    upd_completed_neurons_map =
      case neural_level_map[neuron] do
        ^levels -> completed_neurons_map |> Map.put(neuron, true)
        _ ->
          weights_map[neuron]
            |> Enum.each(fn {_weight, next_neuron} ->
              Neuron.clear_value(next_neuron)
            end)
          completed_neurons_map
      end
    if level_neurons_map[levels] |> Enum.all?(fn n -> upd_completed_neurons_map[n] end) do
      IO.puts "Clear completed"
    end
    {:noreply, %{state|stuff: upd_completed_neurons_map}}
  end

  def handle_cast(:clear_value, %NeuralNetwork{level_neurons: level_neurons} = state) do
    level_neurons[1]
      |> Enum.each(fn neuron ->
        neuron |> Neuron.clear_value()
      end)
    {:noreply, state}
  end

  def handle_cast({process_sentense, sentense}, state) do
    words = sentense |> String.split()
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

  def sentense_to_words(sentense) do
    ~r/\w+/i |> Regex.scan(sentense) |> Stream.map(fn [h|_t] -> h end) |> Enum.map(&(&1 |> String.downcase()))
  end

  def word_to_codepoint_list(word) do
    word |> String.to_charlist() |> Enum.map(fn codepoint -> {codepoint} end)
  end
end
