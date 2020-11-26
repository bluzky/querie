defmodule Querie.Filter do
  import Ecto.Query

  @doc """
  Apply filter on multiple column

  Example:
  %{
    id: 10,
    not: %{
      type: "work"
    },
    or: %{
      team_id: 10,
      and: %{
        team_id: 11,
        role: "manager"
      }
    }
  }

  # id = 10 and not (type = "work") and (team_id = 10 or (team_id = 11 and role = "manager" ))
  """

  def apply(query, filter, opts \\ [])

  def apply(query, filters, opts) when is_list(filters) or is_map(filters) do
    {sort, filters} = Keyword.pop(filters, :_sort, [])

    # skip field starts with underscore
    grouped_by_type =
      filters
      |> Enum.reject(fn
        {_, {column, _}} -> String.starts_with?(to_string(column), "_")
        {column, _} -> String.starts_with?(to_string(column), "_")
        _ -> false
      end)
      |> Enum.group_by(fn
        {_, {:ref, _}} -> :ref
        _ -> :filter
      end)

    column_filter = grouped_by_type[:filter] || []

    column_filter =
      if opts[:skip_nil] do
        Enum.reject(column_filter, fn
          {_, nil} -> true
          {_, {_, nil}} -> true
          _ -> false
        end)
      else
        column_filter
      end

    d_query = filter(:and, column_filter)

    query
    |> where([q], ^d_query)
    |> join_ref(grouped_by_type[:ref])
    |> sort(sort)
  end

  # add single column query condition to existing query
  def filter(query, column, params) do
    d_query = filter(column, params)

    query
    |> where([q], ^d_query)
  end

  @doc """
  Apply filter on single column

  If filter value is list, filter row that match any value in the list
  """

  def filter(:and, filters) when is_map(filters) or is_list(filters) do
    Enum.reduce(filters, true, fn {key, val}, acc ->
      ft = filter(key, val)

      cond do
        ft && acc == true -> dynamic([q], ^ft)
        ft -> dynamic([q], ^acc and ^ft)
        true -> acc
      end
    end)
  end

  def filter(:or, filters) when is_map(filters) or is_list(filters) do
    Enum.reduce(filters, false, fn {key, val}, acc ->
      ft = filter(key, val)

      cond do
        ft && acc == false -> dynamic([q], ^ft)
        ft -> dynamic([q], ^acc or ^ft)
        true -> acc
      end
    end)
  end

  def filter(:not, filters) when is_map(filters) or is_list(filters) do
    d_query = filter(:and, filters)
    dynamic([q], not (^d_query))
  end

  def filter(_column, {:in, nil}) do
    nil
  end

  def filter(column, {:in, values}) do
    dynamic([q], field(q, ^column) in ^values)
  end

  def filter(column, {:is, nil}) do
    dynamic([q], is_nil(field(q, ^column)))
  end

  def filter(column, {:is, value}) do
    dynamic([q], field(q, ^column) == ^value)
  end

  def filter(_column, {_op, nil}) do
    nil
  end

  def filter(column, {:gt, value}) do
    dynamic([q], field(q, ^column) > ^value)
  end

  def filter(column, {:lt, value}) do
    dynamic([q], field(q, ^column) < ^value)
  end

  def filter(column, {:ge, value}) do
    dynamic([q], field(q, ^column) >= ^value)
  end

  def filter(column, {:le, value}) do
    dynamic([q], field(q, ^column) <= ^value)
  end

  def filter(column, {:ne, value}) do
    dynamic([q], field(q, ^column) != ^value)
  end

  def filter(column, {:not, value}) do
    filter(column, {:ne, value})
  end

  def filter(column, {:between, [lower, upper]}) do
    case [lower, upper] do
      [nil, nil] -> nil
      [nil, upper] -> dynamic([q], field(q, ^column) < ^upper)
      [lower, nil] -> dynamic([q], field(q, ^column) > ^lower)
      _ -> dynamic([q], field(q, ^column) > ^lower and field(q, ^column) < ^upper)
    end
  end

  @doc """
  between inclusive
  """
  def filter(column, {:ibetween, [lower, upper]}) do
    case [lower, upper] do
      [nil, nil] -> nil
      [nil, upper] -> dynamic([q], field(q, ^column) <= ^upper)
      [lower, nil] -> dynamic([q], field(q, ^column) >= ^lower)
      _ -> dynamic([q], field(q, ^column) >= ^lower and field(q, ^column) <= ^upper)
    end
  end

  def filter(_, {:between, _}), do: nil
  def filter(_, {:ibetween, _}), do: nil

  def filter(column, {:has, value}) do
    dynamic([q], ^value in field(q, ^column))
  end

  def filter(_, {_, nil}), do: nil

  def filter(column, {:contains, value}) do
    dynamic([q], like(field(q, ^column), ^"%#{value}%"))
  end

  def filter(column, {:icontains, value}) do
    dynamic([q], ilike(field(q, ^column), ^"%#{value}%"))
  end

  def filter(column, {:like, value}) do
    dynamic([q], like(field(q, ^column), ^"%#{value}%"))
  end

  def filter(column, {:ilike, value}) do
    dynamic([q], ilike(field(q, ^column), ^"%#{value}%"))
  end

  def filter(column, values) when is_list(values) do
    filter(column, {:in, values})
  end

  def filter(column, value) do
    filter(column, {:is, value})
  end

  def sort(query, fields) do
    if is_nil(fields) or Enum.empty?(fields) do
      query
    else
      order =
        fields
        |> Enum.map(fn {column, direction} ->
          {direction, column}
        end)

      order_by(query, ^order)
    end
  end

  def join_ref(query, ref, opts \\ [])
  def join_ref(query, nil, _), do: query

  def join_ref(query, refs, query_opts) when is_list(refs) do
    Enum.reduce(refs, query, fn {column, {:ref, ref_filter}}, query ->
      join_ref(query, {column, ref_filter}, query_opts)
    end)
  end

  def join_ref(query, {column, {model, filter, opts}}, query_opts) do
    foreign_key = Keyword.get(opts, :foreign_key, :"#{column}_id")
    references = Keyword.get(opts, :references, :id)

    ref_query = __MODULE__.apply(model, filter, query_opts)
    join(query, :inner, [a], b in ^ref_query, on: field(a, ^foreign_key) == field(b, ^references))
  end

  def join_ref(query, _, _), do: query
end
