defmodule BlogWeb.AboutController do
    use BlogWeb, :controller

    def about(conn, _params) do
        render(conn, :about)
    end
end