defmodule Querie.SchemaHelpers do
  def get_field(schema, field) do
    case Enum.find(schema, fn {k, _} -> to_string(k) == field end) do
      {_, field_def} ->
        {type, opts} =
          if is_atom(field_def) or is_tuple(field_def) do
            {field_def, []}
          else
            Keyword.pop(field_def, :type)
          end

        {field, type, opts}

      _ ->
        nil
    end
  end

  def fields(schema) do
    Map.keys(schema)
  end
end
