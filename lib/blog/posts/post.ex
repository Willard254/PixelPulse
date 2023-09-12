defmodule Blog.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  alias Blog.Comments.Comment

  schema "posts" do
    field :title, :string
    field :body, :string
    has_many :comments, Comment

    #new fields
    field :author, :string
    field :views, :integer

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :author, :views])
    |> validate_required([:title, :body, :author, :views])
  end
end