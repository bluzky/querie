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

defmodule Querie.Parser do
  alias Querie.SchemaHelpers
  alias Querie.ParseContext
  @supported_ops ~w(lt gt ge le is ne in contains icontains between ibetween sort has)

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
    sort_params = Enum.filter(params, fn {op, _} -> op == :sort end)
    filter_params = params -- sort_params

    %ParseContext{sort_params: sort_params, filter_params: filter_params, schema: schema}
  end

  defp parse_condition({key, value}) do
    case String.split(key, "__") do
      [field, op] ->
        if op in @supported_ops do
          {String.to_atom(op), {String.to_atom(field), value}}
        end

      [field] ->
        {:is, {String.to_atom(field), value}}

      _ ->
        nil
    end
  end

  defp parse_value(%{filter_params: params} = context) do
    data =
      params
      |> Enum.map(&cast_field_value(&1, context.schema))

    errors = collect_error(data)

    if length(errors) > 0 do
      struct(context, valid?: false, errors: errors)
    else
      struct(context, filter_data: collect_data(data))
    end
  end

  defp cast_field_value({op, {column, raw_value}}, schema) do
    with {_, type, opts} <- SchemaHelpers.get_field(schema, column),
         type <- (op in ~w(between ibetween)a && {:range, type}) || type,
         {:ok, value} <- Querie.Caster.cast(type, raw_value, opts) do
      {:ok, {op, {column, value}}}
    else
      _ -> {:error, {column, "is invalid"}}
    end
  end

  defp validate_operator(%{valid?: true} = context) do
    validation_data =
      context.sort_params
      |> Enum.map(fn {:sort, {key, direction}} ->
        with {_, true} <- {:column, key in SchemaHelpers.fields(context.schema)},
             {_, true} <- {:direction, direction in ~w(asc desc)} do
          {:ok, {:sort, {key, String.to_atom(direction)}}}
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

  defp validate_operator(context), do: context

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
