defmodule BlogWeb.ContactController do
    use BlogWeb, :controller

    def contact(conn, _params) do
        render(conn, :contact)
    end
end