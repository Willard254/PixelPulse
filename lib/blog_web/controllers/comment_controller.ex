defmodule BlogWeb.CommentController do
    use BlogWeb, :controller

    alias Blog.Posts
    def create(conn, %{"post_id" => post_id, "comment" => comment_params}) do
        post = Posts.get_post!(post_id)

        case Posts.create_comment(post, comment_params) do
            {:ok, _comment} ->
                conn
                |> put_flash(:info, "Comment Added")
                |> redirect(to: ~p"/posts/#{post}")
            {:error, _changeset} ->
                conn
                |> put_flash(:error, "Issue commenting!")
                |> redirect(to: ~p"/posts/#{post}")
        end
    end
end