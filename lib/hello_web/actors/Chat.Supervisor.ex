defmodule Chat.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [],  name: :game_supervisor)
  end

  def start_room(name,user) do
    # And we use `start_child/2` to start a new Chat.Server process
    Supervisor.start_child(:game_supervisor, [name,user])
  end

  def init(_) do
    children = [
      worker(Chat.Server, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end