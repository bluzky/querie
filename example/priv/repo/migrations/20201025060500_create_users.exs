defmodule Example.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :first_name, :string
      add :last_name, :string
      add :email, :string
      add :password, :string
      add :is_active, :boolean, default: true, null: false

      timestamps()
    end

  end
end
