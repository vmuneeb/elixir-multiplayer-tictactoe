defmodule Chat.Registry do
  use GenServer

  # API

  def start_link do
    # We start our registry with a simple name,
    # just so we can reference it in the other functions.
    GenServer.start_link(__MODULE__, nil, name: :registry)
  end

  def whereis_name(room_name) do
    GenServer.call(:registry, {:whereis_name, room_name})
  end

  def register_name(room_name, pid) do
    GenServer.call(:registry, {:register_name, room_name, pid})
  end

  def unregister_name(room_name) do
    GenServer.cast(:registry, {:unregister_name, room_name})
  end

  def send(room_name, message) do
    # If we try to send a message to a process
    # that is not registered, we return a tuple in the format
    # {:badarg, {process_name, error_message}}.
    # Otherwise, we just forward the message to the pid of this
    # room.
    case whereis_name(room_name) do
      :undefined ->
        {:badarg, {room_name, message}}

      pid ->
        Kernel.send(pid, message)
        pid
    end
  end

  # SERVER

  def init(_) do
    # We will use a simple Map to store our processes in
    # the format %{"room name" => pid}
    {:ok, Map.new}
  end

  def handle_call({:whereis_name, room_name}, _from, state) do
    {:reply, Map.get(state, room_name, :undefined), state}
  end

  def handle_call({:register_name, room_name, pid}, _from, state) do
    # Registering a name is just a matter of putting it in our Map.
    # Our response tuple include a `:no` or `:yes` indicating if
    # the process was included or if it was already present.
    case Map.get(state, room_name) do
      nil ->
         # When a new process is registered, we start monitoring it.
        Process.monitor(pid)
        {:reply, :yes, Map.put(state, room_name, pid)}

      _ ->
        {:reply, :no, state}
    end
  end

  def handle_info({:DOWN, _, :process, pid, _}, state) do
    # When a monitored process dies, we will receive a
    # `:DOWN` message that we can use to remove the 
    # dead pid from our registry.
    {:noreply, remove_pid(state, pid)}
  end

  def remove_pid(state, pid_to_remove) do
    # And here we just filter out the dead pid
    remove = fn {_key, pid} -> pid  != pid_to_remove end
    Enum.filter(state, remove) |> Enum.into(%{})
  end

  def handle_cast({:unregister_name, room_name}, state) do
    # And unregistering is as simple as deleting an entry
    # from our Map
    {:noreply, Map.delete(state, room_name)}
  end
end