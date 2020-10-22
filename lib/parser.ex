defmodule Querex.Parser do
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
    param_with_op =
      params
      |> Enum.map(&parse_condition/1)
      |> Enum.reject(&is_nil(&1))

    # params =
    #   param_with_op
    #   |> Enum.map(fn {_, k, v} -> {k, v} end)
    #   |> Enum.into(%{})

    param_with_op
    |> new_context(schema)
    |> parse_value
    |> validate_operator
    |> finalize_result
  end

  defp new_context(params, schema) do
    sort_params = Enum.filter(params, fn {op, _, _} -> op == :sort end)
    filter_params = params -- sort_params

    %Querex.ParseContext{sort_params: sort_params, filter_params: filter_params, schema: schema}
  end

  defp parse_condition({key, value}) do
    case String.split(key, "__") do
      [field, op] ->
        if op in @supported_ops do
          {String.to_atom(op), field, value}
        end

        {op, field, value}

      [field] ->
        {:is, key, value}

      _ ->
        nil
    end
  end

  defp parse_value(context) do
    filter_params =
      context.filter_params
      |> Enum.map(fn {op, k, v} ->
        {k, v}
      end)

    with {:ok, data} <- Tarams.parse(context.schema, filter_params) do
    else
    end
  end

  defp validate_operator(%{valid?: true} = context) do
    {:ok, context}
  end

  defp validate_operator(rs), do: rs

  defp finalize_result(%{valid?: true} = context) do
    {:ok, context.data}
  end

  defp finalize_result(%{valid?: true} = context) do
    {:error, context.errors}
  end
end

defmodule Querex.ParseContext do
  defstruct valid?: false,
            filter_params: [],
            sort_params: [],
            params: [],
            filter_data: [],
            sort_data: [],
            errors: [],
            schema: %{}
end
