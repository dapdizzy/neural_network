defmodule Activator do
  use GenServer

  defstruct [:preceding_neurons, :threshold, :activated_neuron, :signals]

  # API
  def start_link(preceding_neurons, activated_neuron, threshold \\ nil, gen_server_options \\ []) do
    TaskAwaiter |> GenServer.start_link(
      [%Activator
      {
        preceding_neurons: preceding_neurons,
        threshold: threshold,
        signals: %{}
      },
      fn %Activator
      {
        preceding_neurons: preceding_neurons,
        threshold: threshold,
        signals: signals
      } ->
        ((threshold && (signals |> Stream.map(fn {_neuron, signal} -> signal end) |> Enum.sum() >= threshold))
     || (preceding_neurons |> Enum.all?(fn neuron -> signals |> Map.has_key?(neuron) end)))
      end,
      fn %Activator{signals: signals} = state, {neuron, signal} ->
        %{state|signals: signals |> Map.put(neuron, signal)}
      end,
      fn %Activator{signals: signals} = state ->
        total_signal = signals |> Stream.map(fn {_neuron, signal} -> signal end) |> Enum.sum()
        activated_neuron |> Neuron.activate(total_signal)
        %{state|signals: %{}}
      end
   ])
    __MODULE__ |> GenServer.start_link([preceding_neurons, activated_neuron, threshold], gen_server_options)
  end

  def create(preceding_neurons, activated_neuron, threshold \\ 0) do
    {:ok, pid} = start_link(preceding_neurons, activated_neuron, threshold)
    pid
  end

  def accept(activator, neuron, signal) do
    activator |> TaskAwaiter.task_completed({neuron, signal})
     # |> GenServer.cast({:activate, neuron, signal})
  end

  # No callbacks needed thus far. All the work is delegated to the TaskAwaiter module.
  # Callbacks
  # def init([preceding_neurons, activated_neuron, threshold]) do
  #   {:ok, %Activator{preceding_neurons: preceding_neurons, threshold: threshold, activated_neuron: activated_neuron, signals: %{}}}
  # end

  # def handle_cast({:activate, neuron, signal}, %Activator{preceding_neurons: preceding_neurons, threshold: threshold, activated_neuron: activated_neuron, signals: signals} = state) do
  #   upd_signals = signals |> Map.put(neuron, signal)
  #
  #   {:noreply, %{state|signals: upd_signals}}
  # end
end
