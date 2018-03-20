defmodule HelloWeb.PageController do
  use HelloWeb, :controller

  def index(conn, _params) do
    #render conn, "index.html"
    redirect conn, to: "/"<>string_of_length(5)
  end

  def game(conn, %{"game" => game}) do
    render conn, "index.html", game: game
  end

  @chars "ABCDEFGHIJKLMNOPQRSTUVWXYZ" |> String.split("")

  def string_of_length(length) do
    Enum.reduce((1..length), [], fn (_i, acc) ->
      [Enum.random(@chars) | acc]
    end) |> Enum.join("")
  end

end
