defmodule Querex.Caster do
  def cast(type, value, opts \\ [])

  def cast(_, "nil", _) do
    {:ok, nil}
  end

  def cast({:range, type}, value, opts) do
    separator = Keyword.get(opts, :separator, ",")
    parts = String.split(value, separator)

    if length(parts) == 2 do
      Ecto.Type.cast({:array, type}, parts)
    else
      :error
    end
  end

  def cast(type, value, _opts) do
    Ecto.Type.cast(type, value)
  end
end
