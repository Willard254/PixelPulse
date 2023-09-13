defmodule BlogWeb.HomeLive do
    use BlogWeb, :live_view
    alias BlogWeb.Presence
    @topic "users:list"
  
    alias Blog.Accounts.Users
    alias Blog.Repo
  
    def mount(_params, _session, socket) do
      users = Repo.all(Users)
      %{current_users: current_users} = socket.assigns
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Blog.PubSub, @topic)
  
        {:ok, _} = Presence.track(self(), @topic, current_users.id, %{})
      end
  
      socket = socket
        |> assign(:users, users)
        |> assign(:logged_in_users, Map.keys(Presence.list(@topic)))
      {:ok, socket}
    end
  
    def handle_info(%{topic: "users:list", event: "presence_diff", payload: diff}, socket) do
      socket =
        socket
        |> remove_logged_in_users(diff.leaves)
        |> add_logged_in_users(diff.joins)
      {:noreply, socket}
    end
  
    defp remove_logged_in_users(socket, leaves) do
      users = socket.assigns.logged_in_users -- Map.keys(leaves)
      assign(socket, :logged_in_users, users)
    end
  
    defp add_logged_in_users(socket, joins) do
      users = socket.assigns.logged_in_users ++ Map.keys(joins)
      assign(socket, :logged_in_users, users)
    end
  
    def render(assigns) do
      ~H"""
      <b>Users</b>
      <div id="presence">
        <div class="users">
          <ul>
            <li :for={users <- @users}>
              <span class="username">
                <%= users.first_name %>
              </span>
              <span class={if Enum.member?(@logged_in_users, to_string(users.id)), do: "online", else: "offline"}>
              </span>
            </li>
          </ul>
          <span>
          </span>
        </div>
      </div>
      """
    end
  end