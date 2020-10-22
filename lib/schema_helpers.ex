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
