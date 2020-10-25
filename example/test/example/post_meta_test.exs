defmodule Example.PostMetaTest do
  use Example.DataCase

  alias Example.PostMeta

  describe "categories" do
    alias Example.PostMeta.Category

    @valid_attrs %{is_enabled: true, name: "some name", slug: "some slug"}
    @update_attrs %{is_enabled: false, name: "some updated name", slug: "some updated slug"}
    @invalid_attrs %{is_enabled: nil, name: nil, slug: nil}

    def category_fixture(attrs \\ %{}) do
      {:ok, category} =
        attrs
        |> Enum.into(@valid_attrs)
        |> PostMeta.create_category()

      category
    end

    test "list_categories/0 returns all categories" do
      category = category_fixture()
      assert PostMeta.list_categories() == [category]
    end

    test "get_category!/1 returns the category with given id" do
      category = category_fixture()
      assert PostMeta.get_category!(category.id) == category
    end

    test "create_category/1 with valid data creates a category" do
      assert {:ok, %Category{} = category} = PostMeta.create_category(@valid_attrs)
      assert category.is_enabled == true
      assert category.name == "some name"
      assert category.slug == "some slug"
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = PostMeta.create_category(@invalid_attrs)
    end

    test "update_category/2 with valid data updates the category" do
      category = category_fixture()
      assert {:ok, %Category{} = category} = PostMeta.update_category(category, @update_attrs)
      assert category.is_enabled == false
      assert category.name == "some updated name"
      assert category.slug == "some updated slug"
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = category_fixture()
      assert {:error, %Ecto.Changeset{}} = PostMeta.update_category(category, @invalid_attrs)
      assert category == PostMeta.get_category!(category.id)
    end

    test "delete_category/1 deletes the category" do
      category = category_fixture()
      assert {:ok, %Category{}} = PostMeta.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> PostMeta.get_category!(category.id) end
    end

    test "change_category/1 returns a category changeset" do
      category = category_fixture()
      assert %Ecto.Changeset{} = PostMeta.change_category(category)
    end
  end
end
