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
  @supported_ops ~w(lt gt ge le is ne in contains icontains between ibetween sort has ref)

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
  def parse(schema, raw_params) do
    raw_params
    |> split_key_and_operator
    |> parse_with_schema(schema)
  end

  def parse_with_schema(params, schema) do
    params
    |> new_context(schema)
    |> do_parse
    |> validate_operator
    |> finalize_result
  end

  defp split_key_and_operator({key, value}) do
    case String.split(key, "__") do
      [field, operator] ->
        case operator do
          "ref" ->
            {String.to_atom(operator), {String.to_atom(field), split_key_and_operator(value)}}

          op when op in @supported_ops ->
            {String.to_atom(op), {String.to_atom(field), value}}

          _ ->
            nil
        end

      [field] ->
        {:is, {String.to_atom(field), value}}

      _ ->
        nil
    end
  end

  defp split_key_and_operator(params) do
    params
    |> Enum.map(&split_key_and_operator/1)
    |> Enum.reject(&is_nil(&1))
  end

  defp new_context(params, schema) do
    sort_params = Enum.filter(params, fn {op, _} -> op == :sort end)
    filter_params = params -- sort_params

    %ParseContext{sort_params: sort_params, filter_params: filter_params, schema: schema}
  end

  defp do_parse(context) do
    data = cast_schema(context.schema, context.filter_params)

    errors = collect_error(data)

    if length(errors) > 0 do
      struct(context, valid?: false, errors: errors)
    else
      struct(context, filter_data: collect_data(data))
    end
  end

  def cast_schema(schema, params) do
    params
    |> Enum.map(fn {operator, {column, _value}} = field ->
      with field_def <- SchemaHelpers.get_field(schema, column),
           false <- is_nil(field_def),
           {:ok, casted_value} <- cast_field(field, field_def) do
        {:ok, {operator, {column, casted_value}}}
      else
        _ -> {:error, {column, "is invalid"}}
      end
    end)
  end

  # cast nested schema
  defp cast_field({:ref, {_, raw_value}}, {_, _, opts}) do
    with {:ok, schema} <- Keyword.fetch(opts, :schema),
         {:ok, model} <- Keyword.fetch(opts, :model),
         {:ok, casted_value} <- parse_with_schema(raw_value, schema) do
      opts = Keyword.drop(opts, [:schema])
      {:ok, {model, casted_value, opts}}
    end
  end

  defp cast_field({operator, {_, raw_value}}, {_, type, opts})
       when operator in ~w(between ibetween)a do
    Querie.Caster.cast({:range, type}, raw_value, opts)
  end

  defp cast_field({_, {_, raw_value}}, {_, type, opts}) do
    Querie.Caster.cast(type, raw_value, opts)
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
