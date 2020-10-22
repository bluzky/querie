defmodule Querex.Filter do
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
    # build query
    d_query = filter(:and, filters)
    where(query, [q], ^d_query)
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

  def filter(:is, {column, value}) do
    filter(column, value)
  end

  def filter(:is, {column, nil}) do
    dynamic([q], is_nil(field(q, ^column)))
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
    dynamic([q], field(q, ^column) > ^lower and  field(q, ^column) < ^upper)
  end

  @doc"""
  between inclusive
  """
  def filter(:ibetween, {column, [lower, upper]}) do
    dynamic([q], field(q, ^column) >= ^lower and  field(q, ^column) =< ^upper)
  end

  def filter(:contains, {column, value}) do
    dynamic([q], field(q, ^column) like "%#{value}%")
  end

  def filter(:icontains, {column, value}) do
    dynamic([q], field(q, ^column) ilike "%#{value}%")
  end

  def filter(column, values) when is_list(values) do
    filter(:in, {column, values})
  end

  def filter(column, value) do
    filter(:is, {column, value})
  end
end
