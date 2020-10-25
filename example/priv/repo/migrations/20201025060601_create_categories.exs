defmodule Example.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name, :string
      add :slug, :string
      add :is_enabled, :boolean, default: true, null: false

      timestamps()
    end

  end
end
