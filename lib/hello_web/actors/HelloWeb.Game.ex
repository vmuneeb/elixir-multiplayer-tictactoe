defmodule HelloWeb.Game do
  
  def start_link do
    spawn(fn -> listen() end)
  end

  defp listen do
    receive do
      msg -> IO.puts msg
      {user_id,position} -> IO.puts user_id <> "marked " <> position
      _ -> IO.puts :stderr, "Not implemented."
    end
    listen()
  end

end