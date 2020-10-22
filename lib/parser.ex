defmodule Querie.ParseContext do
  defstruct valid?: true,
            filter_params: [],
            sort_params: [],
            params: [],
            filter_data: [],
            sort_data: [],
            errors: [],
            schema: %{}
end

defmodule Querie.SchemaHelpers do
  def get_field(schema, field) do
    field_def = Map.get(schema, field)

    if field_def do
      {type, opts} =
        if is_atom(field_def) or is_tuple(field_def) do
          {field_def, []}
        else
          Keyword.pop(field_def, :type)
        end

      {field, type, opts}
    end
  end

  def fields(schema) do
    Map.keys(schema)
  end
end

defmodule Querie.Parser do
  @supported_ops ~w(lt gt ge le is ne in contains icontains between ibetween sort)

  @doc """
  Parse params and return
  {:ok, filter}
  {:error, errors} errors is a list of tuple [{field, message}]

  Sample schema
  %{
  inserted_at: :date,
  count: {:range, :integer},
  is_active: :boolean,
  name: :string
  }
  """
  def parse(schema, params) do
    params
    |> Enum.map(&parse_condition/1)
    |> Enum.reject(&is_nil(&1))
    |> new_context(schema)
    |> parse_value
    |> validate_operator
    |> finalize_result
  end

  defp new_context(params, schema) do
    sort_params = Enum.filter(params, fn {op, _, _} -> op == :sort end)
    filter_params = params -- sort_params

    %Querie.ParseContext{sort_params: sort_params, filter_params: filter_params, schema: schema}
  end

  defp parse_condition({key, value}) do
    case String.split(key, "__") do
      [field, op] ->
        if op in @supported_ops do
          {String.to_atom(op), String.to_atom(field), value}
        end

      [field] ->
        {:is, String.to_atom(field), value}

      _ ->
        nil
    end
  end

  defp parse_value(context) do
    parsed_data =
      context.filter_params
      |> Enum.map(fn {op, column, raw_value} ->
        with {_, type, opts} <- Querie.SchemaHelpers.get_field(context.schema, column),
             {:ok, value} <- Querie.Caster.cast(type, raw_value, opts) do
          {:ok, {op, column, value}}
        else
          _ -> {:error, {column, "is invalid"}}
        end
      end)

    errors = collect_error(parsed_data)

    if length(errors) > 0 do
      struct(context, valid?: false, errors: errors)
    else
      struct(context, filter_data: collect_data(parsed_data))
    end
  end

  defp validate_operator(%{valid?: true} = context) do
    validation_data =
      context.sort_params
      |> Enum.map(fn {:sort, key, direction} ->
        with {_, true} <- {:column, key in Querie.SchemaHelpers.fields(context.schema)},
             {_, true} <- {:direction, direction in ~w(asc desc)} do
          {:sort, key, String.to_atom(direction)}
        else
          {:column, _} -> {:error, {key, "is not sortable"}}
          {:direction, _} -> {:error, {key, "sort direction is invalid"}}
        end
      end)

    errors = collect_error(validation_data)

    if length(errors) > 0 do
      struct(context, valid?: false, errors: errors)
    else
      struct(context, sort_data: collect_data(validation_data))
    end
  end

  defp validate_operator(rs), do: rs

  defp finalize_result(%{valid?: true} = context) do
    {:ok, context.filter_data ++ context.sort_data}
  end

  defp finalize_result(%{valid?: false} = context) do
    {:error, context.errors}
  end

  defp collect_error(data) do
    Enum.reduce(data, [], fn {status, field}, acc ->
      if status == :error do
        [field | acc]
      else
        acc
      end
    end)
  end

  defp collect_data(data) do
    Enum.reduce(data, [], fn {status, field}, acc ->
      if status == :ok do
        [field | acc]
      else
        acc
      end
    end)
  end
end
