defmodule QuerexTest do
  use ExUnit.Case
  doctest Querex

  test "greets the world" do
    assert Querex.hello() == :world
  end
end
