defmodule Example.PostMeta.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field(:is_enabled, :boolean, default: true)
    field(:name, :string)
    field(:slug, :string)

    timestamps()
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :slug, :is_enabled])
    |> validate_required([:name, :slug, :is_enabled])
  end
end
