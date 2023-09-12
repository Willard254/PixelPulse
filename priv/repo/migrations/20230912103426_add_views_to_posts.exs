defmodule Blog.Repo.Migrations.AddViewsToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :views, :integer, default: 0, null: false
    end
  end
end