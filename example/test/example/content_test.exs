defmodule Example.ContentTest do
  use Example.DataCase

  alias Example.Content

  describe "posts" do
    alias Example.Content.Post

    @valid_attrs %{content: "some content", cover: "some cover", slug: "some slug", state: "some state", title: "some title"}
    @update_attrs %{content: "some updated content", cover: "some updated cover", slug: "some updated slug", state: "some updated state", title: "some updated title"}
    @invalid_attrs %{content: nil, cover: nil, slug: nil, state: nil, title: nil}

    def post_fixture(attrs \\ %{}) do
      {:ok, post} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Content.create_post()

      post
    end

    test "list_posts/0 returns all posts" do
      post = post_fixture()
      assert Content.list_posts() == [post]
    end

    test "get_post!/1 returns the post with given id" do
      post = post_fixture()
      assert Content.get_post!(post.id) == post
    end

    test "create_post/1 with valid data creates a post" do
      assert {:ok, %Post{} = post} = Content.create_post(@valid_attrs)
      assert post.content == "some content"
      assert post.cover == "some cover"
      assert post.slug == "some slug"
      assert post.state == "some state"
      assert post.title == "some title"
    end

    test "create_post/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Content.create_post(@invalid_attrs)
    end

    test "update_post/2 with valid data updates the post" do
      post = post_fixture()
      assert {:ok, %Post{} = post} = Content.update_post(post, @update_attrs)
      assert post.content == "some updated content"
      assert post.cover == "some updated cover"
      assert post.slug == "some updated slug"
      assert post.state == "some updated state"
      assert post.title == "some updated title"
    end

    test "update_post/2 with invalid data returns error changeset" do
      post = post_fixture()
      assert {:error, %Ecto.Changeset{}} = Content.update_post(post, @invalid_attrs)
      assert post == Content.get_post!(post.id)
    end

    test "delete_post/1 deletes the post" do
      post = post_fixture()
      assert {:ok, %Post{}} = Content.delete_post(post)
      assert_raise Ecto.NoResultsError, fn -> Content.get_post!(post.id) end
    end

    test "change_post/1 returns a post changeset" do
      post = post_fixture()
      assert %Ecto.Changeset{} = Content.change_post(post)
    end
  end
end
