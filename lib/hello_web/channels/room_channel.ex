defmodule HelloWeb.RoomChannel do
  use Phoenix.Channel
  alias HelloWeb.Presence
  
  def join("room:" <> room, _params, socket) do
  	IO.puts("Joining " <> room)
  	send(self(), :after_join)
  	user = socket.assigns.user_id  
    IO.puts "where is :"  
    IO.inspect Chat.Registry.whereis_name({:game_name,room})
    if Chat.Registry.whereis_name({:game_name,room}) == :undefined do
      IO.puts "creating room"
      Chat.Supervisor.start_room(room,user)
    else
      IO.puts "room "<>room<>" exist. Adding user"<>user
      Chat.Server.add_user(room,user)
      send(self(), {:next_move,room,Chat.Server.next_user(room),10})
    end
    {:ok, assign(socket, :room, room)}
  end

  def handle_in("message:new", payload, socket) do
    broadcast! socket, "message:new", %{user: payload["user"],  
                                      message: payload["message"]}
    {:noreply, socket}
  end

  def handle_in("next_move", %{"position" => position}, socket) do
  	room = socket.assigns[:room]
  	user = socket.assigns[:user_id]
    res = Chat.Server.make_move(room,user,position)
    IO.inspect res
    case res do
       {true,next_user} -> 
            send(self(), {:next_move,room,next_user,position})
       {:won,user} -> 
            send(self(), {:won,room,user,position})
       {:game_over} -> 
            send(self(), {:game_over,room,user,position})
        _ -> 
           IO.puts "do nothing"        
    end

    # {status,won,next_user} = Chat.Server.make_move(room,user,position)
    # IO.inspect {status,won,next_user}
    # if status do
    #   if won do
    #     send(self(), {:won,room,user,position})
    #   else
    #     send(self(), {:next_move,room,next_user,position})
    #   end
    # end
    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    push socket, "presence_state", Presence.list(socket)
    {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
      online_at: inspect(System.system_time(:seconds))
    })
    {:noreply, socket}
  end

  def handle_info({:next_move,room,next_user,position}, socket) do
    broadcast! socket, "next_move", %{"position"=> position,"user" => next_user}
    {:noreply, socket}
  end

  def handle_info({:won,room,user,position}, socket) do
    broadcast! socket, "won", %{"position"=> position,"user" => user}
    Chat.Registry.unregister_name(room)
    {:noreply, socket}
  end

  def handle_info({:game_over,room,user,position}, socket) do
    broadcast! socket, "game_over",  %{"position"=> position,"user" => user}
    Chat.Registry.unregister_name(room)
    {:noreply, socket}
  end


end