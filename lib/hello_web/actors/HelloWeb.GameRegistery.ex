defmodule HelloWeb.GameRegistery do

  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def roomExist(room) do
    Agent.get(__MODULE__, fn(map) -> nil == Map.get(map,room) end)
  end

  def addUser(room,user) do
	 Agent.update(__MODULE__, fn(map) -> 
	 	gameMap = Map.get(map,room)
	 	if !Enum.member?(Map.get(gameMap,:users), "foo") do
	 		list = Map.get(gameMap,:users) ++ [user]
	 		newMap = Map.put(gameMap,:users,list)
	 		Map.put(map,room,newMap) 
	 	end
	 end)
  end

  def getUsers(room) do
	 Agent.get(__MODULE__, fn(map) -> 
	 	IO.puts "getUsers called"
	 	Map.get(map,room) |> Map.get(:users) end)
  end

  def getActiveUser(room) do
  	Agent.get(__MODULE__,fn(map) -> 
  		gameMap = Map.get(map,room)
  		Map.get(gameMap,:active) end)
  end
  
  def updateActiveUser(room,user_id) do
  	Agent.update(__MODULE__,fn(map) -> 
  		gameMap = Map.get(map,room) 
  		newMap = Map.put(gameMap,:active ,user_id)
  		Map.put(map,room,newMap) end)
  end

  def markMove(room,user,position) do
  	  	Agent.update(__MODULE__,fn(map) -> 
  		board = Map.get(map,room) |> Map.get(:board)
  		 if board[position] == "-" do
  			board = put_in(board[position],user)
  			gameMap = Map.get(map,room)
  			newGameMap = Map.put(gameMap,:board,board)
  			IO.inspect newGameMap
  			Map.put(map,room,newGameMap)
  		 end
  		end)
  end

  def userWon(room,user) do
  	  	Agent.get(__MODULE__,fn(map) -> 
  			board = Map.get(map,room) |> Map.get(:board)
  			if (((board[0] == board[1]) and (board[1] == board[2]) and (board[0] == user)) ||
  			   ((board[0] == board[4]) and (board[4] == board[8]) and (board[8] == user))  ||
  			   ((board[0] == board[3]) and (board[3] == board[6]) and (board[6] == user))  ||
  			   ((board[3] == board[4]) and (board[4] == board[5]) and (board[5] == user))  ||
  			   ((board[6] == board[7]) and (board[7] == board[8]) and (board[6] == user))  ||
  			   ((board[1] == board[4]) and (board[4] == board[7]) and (board[7] == user))  ||
  			   ((board[2] == board[5]) and (board[5] == board[8]) and (board[8] == user))  ||
  			   ((board[2] == board[4]) and (board[4] == board[6]) and (board[5] == user)) ) do
  				true
  			else
  				false
  			end
  		end)
  end

  def create(room,user) do
     Agent.update(__MODULE__, fn(map) -> 
     	board = %{0 => "-", 1 => "-", 2 => "-",
     			  3 => "-", 4 => "-", 5 => "-",
     			  6 => "-", 7 => "-", 8 => "-"}
     	gameMap = %{:users => [user],:active => user, :board => board }
     	Map.put(map,room,gameMap)
     	  end )
  end

end