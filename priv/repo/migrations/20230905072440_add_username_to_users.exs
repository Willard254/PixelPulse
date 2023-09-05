defmodule Blog.Repo.Migrations.AddUsernameToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :username, :string, unique: true, null: false
    end
  end
end