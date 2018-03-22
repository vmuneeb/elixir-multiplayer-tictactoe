defmodule Chat.Server do
  use GenServer

  # API

  def start_link(name,user) do
    GenServer.start_link(__MODULE__, user, name: via_tuple(name))
  end

  def add_user(room_name, user) do
    # And the `GenServer` callbacks will accept this tuple the 
    # same way it accepts a pid or an atom.
    GenServer.call(via_tuple(room_name), {:add_user, user})
  end

  def make_move(room_name,user,position) do
    GenServer.call(via_tuple(room_name), {:make_move,user,position})
  end

  def next_user(room_name) do
    GenServer.call(via_tuple(room_name), {:next_user})
  end

  defp via_tuple(room_name) do
    # And the tuple always follow the same format:
    # {:via, module_name, term}
    {:via, Chat.Registry, {:game_name, room_name}}
  end

  # SERVER

  def init(user) do
    IO.puts "Starting Chat server with user "<>user 
    board = %{
            0 => "-", 1 => "-", 2 => "-",
            3 => "-", 4 => "-", 5 => "-",
            6 => "-", 7 => "-", 8 => "-"}
      map = %{:users => [user],:active => user, :board => board }
    {:ok, map}
  end

  def handle_call({:make_move, user,position},_from, map) do
     board = Map.get(map,:board)
     active = Map.get(map,:active)     
     next_user = Map.get(map,:users) -- [active] |> hd
     IO.puts "user "<>user <> " active "<>active <>" next user: "<>next_user
     IO.puts "board[position] "<>board[position]
     if user == active and board[position] == "-" do
        board = put_in(board[position],user)
        map = Map.put(map,:board,board) 
        |> Map.put(:active,next_user)
        cond do
          user_won(board,user) ->
            {:reply, {:won,user},map}
          !game_pending(board) ->
            {:reply,{:game_over},map}
          true ->
            {:reply, {true,next_user},map}
        end
      else
         {:reply, {:do_nothing},map}
      end      
  end

  def handle_call({:add_user, user},_from, map) do
    if (length(Map.get(map,:users)) < 2) and !Enum.member?(Map.get(map,:users), user) do
      list = Map.get(map,:users) ++ [user]
      map = Map.put(map,:users,list)
      {:reply, true,map}
    else
      {:reply, false,map}  
    end
  end

  defp game_pending(board) do
    Map.values(board) 
    |> Enum.member?("-")
  end

  def handle_call({:next_user},_from, map) do
    {:reply, Map.get(map,:active),map}
  end

    defp user_won(board,user) do
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
    end

end