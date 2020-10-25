defmodule Example.Content.Post do
  use Ecto.Schema
  import Ecto.Changeset

  def state_enum(), do: ~w(draft published archived trash)

  schema "posts" do
    field(:content, :string)
    field(:cover, :string)
    field(:slug, :string)
    field(:state, :string, default: "draft")
    field(:title, :string)
    belongs_to(:category, Example.PostMeta.Category)
    belongs_to(:author, Example.Account.User)

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :slug, :cover, :content, :state, :author_id, :category_id])
    |> validate_required([:title, :content, :state])
  end
end
