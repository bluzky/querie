defmodule QuerieTest do
  use ExUnit.Case
  doctest Querie

  test "parse string" do
    schema = %{
      name: :string
    }

    params = %{"name" => "dzung"}
    {code, data} = Querie.Parser.parse(schema, params)
    assert code == :ok
    assert is_list(data)
    assert [{:is, {:name, "dzung"}} | _] = data
  end

  test "parse string invalid" do
    schema = %{
      name: :string
    }

    params = %{"name" => 123}
    {code, data} = Querie.Parser.parse(schema, params)
    assert code == :error
    assert Enum.find_value(data, false, fn {field, _} -> field == :name end)
  end

  test "parse integer range" do
    schema = %{
      age: {:range, :integer}
    }

    params = %{"age" => "18,45"}
    {code, data} = Querie.Parser.parse(schema, params)
    assert code == :ok
    assert [{:is, {:age, [18, 45]}} | _] = data
  end

  test "parse integer range with custom separator" do
    schema = %{
      age: [type: {:range, :integer}, separator: "+"]
    }

    params = %{"age" => "18+45"}
    {code, data} = Querie.Parser.parse(schema, params)
    assert code == :ok
    assert [{:is, {:age, [18, 45]}} | _] = data
  end

  test "parse date range" do
    schema = %{
      date: {:range, :date}
    }

    params = %{"date" => "2020-10-10,2020-10-20"}
    {code, data} = Querie.Parser.parse(schema, params)
    assert code == :ok
    assert [{:is, {:date, [~D[2020-10-10], ~D[2020-10-20]]}} | _] = data
  end

  test "parse operator" do
    schema = %{
      age: :integer
    }

    Enum.each(~w(lt gt ge le is ne in contains icontains between ibetween)a, fn op ->
      params = %{"age__#{op}" => "20"}
      {code, data} = Querie.Parser.parse(schema, params)
      assert code == :ok
      assert [{^op, {:age, 20}} | _] = data
    end)
  end
end
