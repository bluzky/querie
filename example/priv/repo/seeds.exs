# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Example.Repo.insert!(%Example.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
defmodule Seeds do
  alias Example.Account
  alias Example.PostMeta
  alias Example.Content
  alias Example.Content.Post

  def run() do
    users = seed_user()
    categories = seed_category()
    seed_post(users, categories)
  end

  def seed_user() do
    [
      %{
        first_name: "John",
        last_name: "Smith",
        email: "user1@example.com",
        is_active: false
      },
      %{
        first_name: "Sam",
        last_name: "Son",
        email: "sam@example.com",
        is_active: true
      },
      %{
        first_name: "Jane",
        last_name: "Gordon",
        email: "jane@example.com",
        is_active: true
      }
    ]
    |> Enum.map(fn item ->
      Account.create_user(item)
    end)
    |> Enum.filter(&(elem(&1, 0) == :ok))
    |> Enum.map(&elem(&1, 1))
  end

  def seed_category() do
    [
      %{
        name: "Elixir",
        slug: "elixir",
        is_enabled: true
      },
      %{
        name: "Phoenix",
        slug: "phoenix",
        is_enabled: true
      },
      %{
        name: "Erlang",
        slug: "erlang",
        is_enabled: false
      },
      %{
        name: "Javascript",
        slug: "javascript",
        is_enabled: true
      }
    ]
    |> Enum.map(fn item ->
      PostMeta.create_category(item)
    end)
    |> Enum.filter(&(elem(&1, 0) == :ok))
    |> Enum.map(&elem(&1, 1))
  end

  def seed_post(users, categories) do
    Enum.each(1..10, fn number ->
      author = Enum.random(users)
      category = Enum.random(categories)

      %{
        title: "post #{number} in #{category.name} by #{author.first_name}",
        content: "Hi this is a sample post content by #{author.first_name}. Edit me",
        state: Enum.random(Post.state_enum()),
        author_id: author.id,
        category_id: category.id,
        view_count: :rand.uniform(100)
      }
      |> Content.create_post()
    end)
  end
end

Seeds.run()
