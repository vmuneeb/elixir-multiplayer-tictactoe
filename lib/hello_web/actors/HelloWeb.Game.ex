defmodule HelloWeb.Game do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__,  %{}, name: :chat_room)
  end



  def add_user(user) do
    
  end

  def make_move(user,position) do
    
  end

  def won do
    
  end

  def game_started do
    
  end

  def user_left do
    
  end


end