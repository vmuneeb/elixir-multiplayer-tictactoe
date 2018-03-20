defmodule HelloWeb.RoomChannel do
  use Phoenix.Channel
  alias HelloWeb.Presence
  
  def join("room:" <> room, _params, socket) do
  	IO.puts("Joining " <> room)
  	send(self(), :after_join)
  	user_id = socket.assigns.user_id
  	if HelloWeb.GameRegistery.roomExist( room) do
  		IO.puts "Creating room "<> room<> "with user "<>user_id
  		HelloWeb.Game.start_link()
  		HelloWeb.GameRegistery.create(room,user_id)
  	else 
  		users = HelloWeb.GameRegistery.getUsers(room)
  		if !Enum.member?(users, user_id) do
  			IO.puts user_id<> " is not a member of"
  			HelloWeb.GameRegistery.addUser(room,user_id)  
  			next_user = hd users
  			IO.puts "next user is " <> next_user
  			send(self(), {:next_move,room,next_user,10})
  		end
  	end
    {:ok, assign(socket, :room, room)}
  end

  # def leave(socket, topic) do
  # 	user_id = socket.assigns[:user_id]
  # 	IO.puts "user leaving "<>user_id
  #   broadcast socket, "user:left", %{ "content" => "somebody is leaving" }
  #   {:ok, socket}
  # end

  def handle_in("next_move", %{"position" => position}, socket) do
  	room = socket.assigns[:room]
  	user_id = socket.assigns[:user_id]
  	users = HelloWeb.GameRegistery.getUsers(room)
  	active_user = HelloWeb.GameRegistery.getActiveUser(room)
  	IO.puts "next_move received from "<>user_id
  	IO.puts "active user is : "<> active_user
  	if(user_id == active_user) do
  		next_user = users -- [user_id] |> hd  	
  		IO.puts "Sending next move to "<> next_user	
  		HelloWeb.GameRegistery.markMove(room,user_id,position)
  		IO.inspect HelloWeb.GameRegistery.userWon(room,user_id)
  		if HelloWeb.GameRegistery.userWon(room,user_id) do
  			send(self(), {:won,room,user_id,position})
  		else 
  			send(self(), {:next_move,room,next_user,position})
  			HelloWeb.GameRegistery.updateActiveUser(room,next_user)
  		end
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

  def handle_info({:next_move,room,next_user,position}, socket) do
    broadcast! socket, "next_move", %{"position"=> position,"user" => next_user}
    HelloWeb.GameRegistery.updateActiveUser(room,next_user)
    {:noreply, socket}
  end

  def handle_info({:won,room,user,position}, socket) do
    broadcast! socket, "won", %{"position"=> position,"user" => user}
    HelloWeb.GameRegistery.updateActiveUser(room,user)
    {:noreply, socket}
  end

end