defmodule ExampleWeb.PostController do
  use ExampleWeb, :controller

  alias Example.Content
  alias Example.Content.Post
  alias Example.PostMeta.Category
  alias Example.Account.User
  alias Example.Repo
  require Logger

  @post_filter_schema %{
    title: :string,
    view_count: :integer,
    state: :string,
    author: [
      type: :ref,
      model: User,
      schema: %{
        email: :string,
        first_name: :string
      }
    ],
    category: [
      type: :ref,
      model: Category,
      schema: %{
        name: :string,
        is_enabled: :boolean
      }
    ]
  }

  def index(conn, params) do
    with {:ok, filter} <- Querie.parse(@post_filter_schema, params) do
      posts =
        Querie.filter(Post, filter)
        |> Repo.all()
        |> Repo.preload([:category, :author])

      render(conn, "index.html", posts: posts, errors: nil)
    else
      {:error, err} ->
        Logger.error(inspect(err))
        render(conn, "index.html", posts: [], errors: err)
    end
  end

  def new(conn, _params) do
    changeset = Content.change_post(%Post{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"post" => post_params}) do
    case Content.create_post(post_params) do
      {:ok, post} ->
        conn
        |> put_flash(:info, "Post created successfully.")
        |> redirect(to: Routes.post_path(conn, :show, post))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    post = Content.get_post!(id)
    render(conn, "show.html", post: post)
  end

  def edit(conn, %{"id" => id}) do
    post = Content.get_post!(id)
    changeset = Content.change_post(post)
    render(conn, "edit.html", post: post, changeset: changeset)
  end

  def update(conn, %{"id" => id, "post" => post_params}) do
    post = Content.get_post!(id)

    case Content.update_post(post, post_params) do
      {:ok, post} ->
        conn
        |> put_flash(:info, "Post updated successfully.")
        |> redirect(to: Routes.post_path(conn, :show, post))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", post: post, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    post = Content.get_post!(id)
    {:ok, _post} = Content.delete_post(post)

    conn
    |> put_flash(:info, "Post deleted successfully.")
    |> redirect(to: Routes.post_path(conn, :index))
  end
end
