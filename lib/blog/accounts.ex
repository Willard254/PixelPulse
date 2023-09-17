defmodule Blog.Accounts do

  import Ecto.Query, warn: false
  alias Blog.Repo

  alias Blog.Accounts.{Users, UsersToken, UsersNotifier}
  
  def get_users_by_email(email) when is_binary(email) do
    Repo.get_by(Users, email: email)
  end

  def get_users_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    users = Repo.get_by(Users, email: email)
    if Users.valid_password?(users, password), do: users
  end

  def get_users!(id), do: Repo.get!(Users, id)

  def register_users(attrs) do
    %Users{}
    |> Users.registration_changeset(attrs)
    |> Repo.insert()
  end

  def change_users_registration(%Users{} = users, attrs \\ %{}) do
    Users.registration_changeset(users, attrs, hash_password: false, validate_email: false)
  end

  def change_users_email(users, attrs \\ %{}) do
    Users.email_changeset(users, attrs, validate_email: false)
  end

  def apply_users_email(users, password, attrs) do
    users
    |> Users.email_changeset(attrs)
    |> Users.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  def update_users_email(users, token) do
    context = "change:#{users.email}"

    with {:ok, query} <- UsersToken.verify_change_email_token_query(token, context),
         %UsersToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(users_email_multi(users, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp users_email_multi(users, email, context) do
    changeset =
      users
      |> Users.email_changeset(%{email: email})
      |> Users.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:users, changeset)
    |> Ecto.Multi.delete_all(:tokens, UsersToken.users_and_contexts_query(users, [context]))
  end

  def deliver_users_update_email_instructions(%Users{} = users, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, users_token} = UsersToken.build_email_token(users, "change:#{current_email}")

    Repo.insert!(users_token)
    UsersNotifier.deliver_update_email_instructions(users, update_email_url_fun.(encoded_token))
  end

  def change_users_password(users, attrs \\ %{}) do
    Users.password_changeset(users, attrs, hash_password: false)
  end

  def update_users_password(users, password, attrs) do
    changeset =
      users
      |> Users.password_changeset(attrs)
      |> Users.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:users, changeset)
    |> Ecto.Multi.delete_all(:tokens, UsersToken.users_and_contexts_query(users, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{users: users}} -> {:ok, users}
      {:error, :users, changeset, _} -> {:error, changeset}
    end
  end

  def generate_users_session_token(users) do
    {token, users_token} = UsersToken.build_session_token(users)
    Repo.insert!(users_token)
    token
  end

  def get_users_by_session_token(token) do
    {:ok, query} = UsersToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def delete_users_session_token(token) do
    Repo.delete_all(UsersToken.token_and_context_query(token, "session"))
    :ok
  end

  def deliver_users_confirmation_instructions(%Users{} = users, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if users.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, users_token} = UsersToken.build_email_token(users, "confirm")
      Repo.insert!(users_token)
      UsersNotifier.deliver_confirmation_instructions(users, confirmation_url_fun.(encoded_token))
    end
  end

  def confirm_users(token) do
    with {:ok, query} <- UsersToken.verify_email_token_query(token, "confirm"),
         %Users{} = users <- Repo.one(query),
         {:ok, %{users: users}} <- Repo.transaction(confirm_users_multi(users)) do
      {:ok, users}
    else
      _ -> :error
    end
  end

  defp confirm_users_multi(users) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:users, Users.confirm_changeset(users))
    |> Ecto.Multi.delete_all(:tokens, UsersToken.users_and_contexts_query(users, ["confirm"]))
  end

  def deliver_users_reset_password_instructions(%Users{} = users, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, users_token} = UsersToken.build_email_token(users, "reset_password")
    Repo.insert!(users_token)
    UsersNotifier.deliver_reset_password_instructions(users, reset_password_url_fun.(encoded_token))
  end

  def get_users_by_reset_password_token(token) do
    with {:ok, query} <- UsersToken.verify_email_token_query(token, "reset_password"),
         %Users{} = users <- Repo.one(query) do
      users
    else
      _ -> nil
    end
  end

  def reset_users_password(users, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:users, Users.password_changeset(users, attrs))
    |> Ecto.Multi.delete_all(:tokens, UsersToken.users_and_contexts_query(users, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{users: users}} -> {:ok, users}
      {:error, :users, changeset, _} -> {:error, changeset}
    end
  end
end