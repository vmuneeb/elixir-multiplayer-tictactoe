defmodule HelloWeb.RoomChannel do
  use Phoenix.Channel
  alias HelloWeb.Presence
  require Logger


  def terminate(_reason, socket) do
    user = socket.assigns.user_id  
    room = socket.assigns[:room]
    Logger.info user<>" is LEAVING"
    if Chat.Server.is_member(room,user) do
      send(self(), {:player_left,room,user})
    end
    {:ok, socket}
  end

  def join("room:" <> room, _params, socket) do
  	IO.puts("Joining " <> room)
  	send(self(), :after_join)
  	user = socket.assigns.user_id  
    if Chat.Registry.whereis_name({:game_name,room}) == :undefined do
      Logger.info "creating room "<>room
      Chat.Supervisor.start_room(room)
      Chat.Server.add_user(room,user)
    else
      Logger.info "room "<>room<>" exist. Adding user"<>user
      case Chat.Server.add_user(room,user)  do
        :ok -> send(self(), {:next_move,room,Chat.Server.next_user(room),10})
        :error -> send(self(), {:room_full,room,user})
      end            
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
           Logger.info "do nothing"        
    end
    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    push socket, "presence_state", Presence.list(socket)
    {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
      online_at: inspect(System.system_time(:seconds))
    })
    {:noreply, socket}
  end

  def handle_info({:next_move,_room,next_user,position}, socket) do
    broadcast! socket, "next_move", %{"position"=> position,"user" => next_user}
    {:noreply, socket}
  end

  def handle_info({:room_full,_room,user}, socket) do
    broadcast! socket, "room_full", %{"user" => user}
    {:noreply, socket}
  end

  def handle_info({:won,room,user,position}, socket) do
    broadcast! socket, "won", %{"position"=> position,"user" => user} 
    IO.inspect Chat.Registry.whereis_name({:game_name,room})
    Chat.Supervisor.stop_room(room)  
    {:noreply, socket}
  end
 
  def handle_info({:game_over,room,user,position}, socket) do
    broadcast! socket, "game_over",  %{"position"=> position,"user" => user}
    Chat.Supervisor.stop_room(room)   
    {:noreply, socket}
  end

  def handle_info({:player_left,room,user}, socket) do
    broadcast! socket, "player_left",  %{"user" => user}
    Chat.Supervisor.stop_room(room)   
    {:noreply, socket}
  end


end