defmodule Blog.Posts do
    import Ecto.Query, warn: false
    alias Blog.Repo
    alias Blog.Posts
    alias Blog.Posts.Post
    alias Blog.Comments.Comment

    def list_posts do
        Repo.all(Post)
    end

    def get_post!(id) do
      Post
      |> Repo.get!(id)
      |> Repo.preload(:comments)
    end

    def create_post(attrs \\ %{}) do
        %Post{}
        |> Post.changeset(attrs)
        |> Repo.insert()
    end

    def update_post(%Post{} = post, attrs) do
        post
        |> Post.changeset(attrs)
        |> Repo.update()
      end
    
    def delete_post(%Post{} = post) do
      Repo.delete(post)
    end

    def change_post(%Post{} = post, attrs \\ %{}) do
      Post.changeset(post, attrs)
    end

    def inc_post_views(%Post{} = post) do
      {1, [%Post{views: views}]} =
        from(p in Post, where: p.id == ^post.id, select: [:views])
        |> Repo.update_all(inc: [views: 1])

      put_in(post.views, views)
    end

    def create_comment(%Post{} = post, attrs \\ %{}) do
      post
      |> Ecto.build_assoc(:comments)
      |> Comment.changeset(attrs)
      |> Repo.insert()
    end

    def list_comments do
      Repo.all(Comment)
    end
  
    def get_comment!(id), do: Repo.get!(Comment, id)
  
    def update_comment(%Comment{} = comment, attrs) do
      comment
      |> Comment.changeset(attrs)
      |> Repo.update()
    end
  
    def delete_comment(%Comment{} = comment) do
      Repo.delete(comment)
    end
  
    def change_comment(%Comment{} = comment, attrs \\ %{}) do
      Comment.changeset(comment, attrs)
    end

    def get_number_of_comments(post_id) do
      post = Posts.get_post!(post_id) |> Repo.preload([:comments])
      Enum.count(post.comments)
    end
end