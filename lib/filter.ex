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
  def apply(query, filters) when is_list(filters) or is_map(filters) do
    # skip field starts with underscore
    grouped_by_type =
      filters
      |> Enum.reject(fn
        {_, {column, _}} -> String.starts_with?(to_string(column), "_")
        _ -> false
      end)
      |> Enum.group_by(fn {operator, _} ->
        # group type of operator sort, ref and filter for different logic
        if operator in [:sort, :ref] do
          operator
        else
          :filter
        end
      end)

    d_query = filter(:and, grouped_by_type[:filter] || [])

    query
    |> where([q], ^d_query)
    |> sort(grouped_by_type[:sort])
    |> join_ref(grouped_by_type[:ref])
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

  def filter(:in, {_column, nil}) do
    nil
  end

  def filter(:in, {column, values}) do
    dynamic([q], field(q, ^column) in ^values)
  end

  def filter(:is, {column, nil}) do
    dynamic([q], is_nil(field(q, ^column)))
  end

  def filter(:is, {column, value}) do
    dynamic([q], field(q, ^column) == ^value)
  end

  def filter(_op, {_column, nil}) do
    nil
  end

  def filter(:gt, {column, value}) do
    dynamic([q], field(q, ^column) > ^value)
  end

  def filter(:lt, {column, value}) do
    dynamic([q], field(q, ^column) < ^value)
  end

  def filter(:ge, {column, value}) do
    dynamic([q], field(q, ^column) >= ^value)
  end

  def filter(:le, {column, value}) do
    dynamic([q], field(q, ^column) > ^value)
  end

  def filter(:ne, {column, value}) do
    dynamic([q], field(q, ^column) != ^value)
  end

  def filter(:not, {column, value}) do
    filter(:ne, {column, value})
  end

  def filter(:between, {column, [lower, upper]}) do
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
  def filter(:ibetween, {column, [lower, upper]}) do
    case [lower, upper] do
      [nil, nil] -> nil
      [nil, upper] -> dynamic([q], field(q, ^column) <= ^upper)
      [lower, nil] -> dynamic([q], field(q, ^column) >= ^lower)
      _ -> dynamic([q], field(q, ^column) >= ^lower and field(q, ^column) <= ^upper)
    end
  end

  def filter(:ibetween, _), do: nil
  def filter(:between, _), do: nil

  def filter(:has, {column, value}) do
    dynamic([q], ^value in field(q, ^column))
  end

  def filter(:contains, {column, value}) do
    dynamic([q], like(field(q, ^column), ^"%#{value}%"))
  end

  def filter(:icontains, {column, value}) do
    dynamic([q], ilike(field(q, ^column), ^"%#{value}%"))
  end

  def filter(column, values) when is_list(values) do
    filter(:in, {column, values})
  end

  def filter(column, value) do
    filter(:is, {column, value})
  end

  def sort(query, fields) do
    if is_nil(fields) or Enum.empty?(fields) do
      query
    else
      order =
        fields
        |> Enum.map(fn {_, {column, direction}} ->
          {direction, column}
        end)

      order_by(query, ^order)
    end
  end

  def join_ref(query, nil), do: query

  def join_ref(query, refs) when is_list(refs) do
    Enum.reduce(refs, query, fn {_, ref_filter}, query ->
      join_ref(query, ref_filter)
    end)
  end

  def join_ref(query, {column, {model, filter, opts}}) do
    foreign_key = Keyword.get(opts, :foreign_key, :"#{column}_id")
    references = Keyword.get(opts, :references, :id)

    ref_query = __MODULE__.apply(model, filter)
    join(query, :inner, [a], b in ^ref_query, on: field(a, ^foreign_key) == field(b, ^references))
  end

  def join_ref(query, _), do: query
end
