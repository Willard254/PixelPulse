defmodule BlogWeb.PrivacyController do
    use BlogWeb, :controller

    def privacy(conn, _params) do
        render(conn, :privacy)
    end
end