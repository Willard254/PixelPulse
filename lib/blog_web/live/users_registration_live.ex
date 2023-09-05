defmodule BlogWeb.UsersRegistrationLive do
  use BlogWeb, :live_view

  alias Blog.Accounts
  alias Blog.Accounts.Users

  def render(assigns) do
    ~H"""
    <div class="mx-0 max-w-sm">
      <.header class=" ">
        Register
        <:subtitle>
          Have an Account?
          <.link navigate={~p"/users/log_in"} class="font-semibold text-brand hover:underline">
            Sign in
          </.link>
            Access your account now.
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="registration_form" phx-submit="save" phx-change="validate" phx-trigger-action={@trigger_submit} action={~p"/users/log_in?_action=registered"} method="post"> 
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input field={@form[:first_name]} type="text" label="First Name" required />
        <.input field={@form[:last_name]} type="text" label="Last Name" required />
        <.input field={@form[:username]} type="text" label="Username" required />
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="New password" required />
        <.input field={@form[:password_confirmation]} type="password" label="Confirm new password" required/>

        <:actions>
          <.button phx-disable-with="Creating account..." class="w-full">Create an account</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_users_registration(%Users{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"users" => users_params}, socket) do
    case Accounts.register_users(users_params) do
      {:ok, users} ->
        {:ok, _} =
          Accounts.deliver_users_confirmation_instructions(
            users,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_users_registration(users)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"users" => users_params}, socket) do
    changeset = Accounts.change_users_registration(%Users{}, users_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "users")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end