defmodule OutputCollector do
  use GenServer
  defstruct [:values]

  # API
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def collect(value) do
    __MODULE__ |> GenServer.cast({:collect, value})
  end

  def get_values do
    __MODULE__ |> GenServer.call(:get_values)
  end

  # Callbacks
  def init(initial_values) do
    {:ok, %OutputCollector{values: initial_values}}
  end

  def handle_cast({:collect, value}, %OutputCollector{values: values} = state) do
    {:noreply, put_in(state.values, [value|values])}
  end

  def handle_call(:get_values, _from, %OutputCollector{values: values} = state) do
    {:reply, values, state}
  end
end
