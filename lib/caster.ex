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
    cast({:range, type}, [values["min"], values["max"]], opts)
  end

  def cast({:range, type}, value, opts) when is_binary(value) do
    separator = Keyword.get(opts, :separator, ",")
    parts = String.split(value, separator)
    cast({:range, type}, parts, opts)
  end

  def cast({:range, type}, values, opts) do
    with true <- length(values) == 2,
         {:ok, [min, max]} = ok <- cast_range(type, values, opts) do
      if is_nil(min) and is_nil(max) do
        {:ok, nil}
      else
        ok
      end
    else
      _ ->
        :error
    end
  end

  # empty string is casted to nil
  def cast(_, "", _), do: {:ok, nil}

  def cast(type, value, opts) do
    cast_func = Keyword.get(opts, :cast_func)

    if is_function(cast_func) do
      cast_func.(value)
    else
      Ecto.Type.cast(type, value)
    end
  end

  def cast_range(type, values, opts) do
    values
    |> Enum.reduce({true, []}, fn value, {valid, casted_values} ->
      case cast(type, value, opts) do
        {:ok, val} -> {valid, [val | casted_values]}
        err -> {false, [err | casted_values]}
      end
    end)
    |> case do
      {false, _} -> :error
      {true, values} -> {:ok, Enum.reverse(values)}
    end
  end
end
