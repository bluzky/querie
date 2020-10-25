defmodule Example.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string
      add :slug, :string
      add :cover, :string
      add :content, :string
      add :state, :string
      add :category_id, references(:categories, on_delete: :nothing)
      add :author_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:posts, [:category_id])
    create index(:posts, [:author_id])
  end
end
