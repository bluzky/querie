defmodule Querie do
  alias Querie.Parser
  alias Querie.Filter

  def parse(schema, params) do
    Parser.parse(schema, params)
  end

  def filter(query, filters) do
    Filter.apply(query, filters)
  end
end
