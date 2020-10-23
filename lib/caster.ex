defmodule Querie.Caster do
  def cast(type, value, opts \\ [])

  def cast(_, "nil", _) do
    {:ok, nil}
  end

  @doc """
  cast range with object
  %{from => val, to => val}
  """
  def cast({:range, type}, values, opts) when is_map(values) do
    case values do
      %{"min" => min, "max" => max} ->
        cast({:range, type}, [min, max], opts)

      _ ->
        :error
    end
  end

  def cast({:range, type}, value, opts) when is_binary(value) do
    separator = Keyword.get(opts, :separator, ",")
    parts = String.split(value, separator)
    cast({:range, type}, parts, opts)
  end

  def cast({:range, type}, values, opts) do
    if length(values) == 2 do
      cast_array(type, values, opts)
    else
      :error
    end
  end

  def cast(:date, value, opts) do
    format = Keyword.get(opts, :format, "{YYYY}-{0M}-{0D}")

    case Timex.parse(value, format) do
      {:error, _} -> :error
      ok -> ok
    end
  end

  def cast(type, value, _opts) do
    Ecto.Type.cast(type, value)
  end

  def cast_array(type, values, opts) do
    values
    |> Enum.reduce({true, []}, fn value, {valid, casted_values} ->
      case cast(type, value, opts) do
        {:ok, val} -> {valid, [val | casted_values]}
        _ -> {false, casted_values}
      end
    end)
    |> case do
      {false, _} -> :error
      {true, values} -> {:ok, Enum.reverse(values)}
    end
  end
end
