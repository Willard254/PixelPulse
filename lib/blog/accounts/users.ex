defmodule Blog.Accounts.Users do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :naive_datetime
    field :username, :string
    field :first_name, :string
    field :last_name, :string
    timestamps()
  end

  def registration_changeset(users, attrs, opts \\ []) do
    users
    |> cast(attrs, [:email, :password, :username, :first_name, :last_name])
    |> validate_email(opts)
    |> validate_password(opts)
    |> validate_username(opts)
    |> validate_first_name(opts)
    |> validate_last_name(opts)
  end

  defp validate_first_name(changeset, _opts) do
    changeset
    |> validate_required([:first_name])
  end

  defp validate_last_name(changeset, _opts) do
    changeset
    |> validate_required([:last_name])
  end

  defp validate_username(changeset, opts) do
    changeset
      |> validate_required([:username])
      # |> validate_format([:username, ~r/^[a-zA-Z0-9]+$/, message: "wrong format!"])
      |> maybe_validate_unique_username(opts)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Blog.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  defp maybe_validate_unique_username(changeset, opts) do
    if Keyword.get(opts, :validate_username, true) do
      changeset
      |> unsafe_validate_unique(:username, Blog.Repo)
      |> unique_constraint(:username)
    else
      changeset
    end
  end

  def email_changeset(users, attrs, opts \\ []) do
    users
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  def password_changeset(users, attrs, opts \\ []) do
    users
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  def confirm_changeset(users) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(users, confirmed_at: now)
  end

  def valid_password?(%Blog.Accounts.Users{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end