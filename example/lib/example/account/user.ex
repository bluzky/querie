defmodule Example.Account.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:email, :string)
    field(:first_name, :string)
    field(:is_active, :boolean, default: true)
    field(:last_name, :string)
    field(:password, :string)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :email, :password, :is_active])
    |> validate_required([:first_name, :last_name, :email])
  end
end
