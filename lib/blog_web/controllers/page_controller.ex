defmodule BlogWeb.PageController do
  use BlogWeb, :controller

  def home(conn, _params) do
    # posts = Posts.list_posts()
    render(conn, :home, layout: false)
  end
end