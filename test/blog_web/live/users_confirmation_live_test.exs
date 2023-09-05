defmodule BlogWeb.UsersConfirmationLiveTest do
  use BlogWeb.ConnCase

  import Phoenix.LiveViewTest
  import Blog.AccountsFixtures

  alias Blog.Accounts
  alias Blog.Repo

  setup do
    %{users: users_fixture()}
  end

  describe "Confirm users" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/confirm/some-token")
      assert html =~ "Confirm Account"
    end

    test "confirms the given token once", %{conn: conn, users: users} do
      token =
        extract_users_token(fn url ->
          Accounts.deliver_users_confirmation_instructions(users, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/users/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Users confirmed successfully"

      assert Accounts.get_users!(users.id).confirmed_at
      refute get_session(conn, :users_token)
      assert Repo.all(Accounts.UsersToken) == []

      # when not logged in
      {:ok, lv, _html} = live(conn, ~p"/users/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Users confirmation link is invalid or it has expired"

      # when logged in
      {:ok, lv, _html} =
        build_conn()
        |> log_in_users(users)
        |> live(~p"/users/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, users: users} do
      {:ok, lv, _html} = live(conn, ~p"/users/confirm/invalid-token")

      {:ok, conn} =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Users confirmation link is invalid or it has expired"

      refute Accounts.get_users!(users.id).confirmed_at
    end
  end
end
