defmodule Chat.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [],  name: :game_supervisor)
  end

  def start_room(name) do
    # And we use `start_child/2` to start a new Chat.Server process
    Supervisor.start_child(:game_supervisor, [name])
  end

  def stop_room(name) do
    # And we use `start_child/2` to start a new Chat.Server process
    Supervisor.stop(Chat.Registry.whereis_name({:game_name,name}),{:game_supervisor, [name]})
  end

  def init(_) do
    children = [
      worker(Chat.Server, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end