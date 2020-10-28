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
    assert %{filter: {:is, {:name, "dzung"}}} = data
  end

  test "parse string invalid" do
    schema = %{
      name: :string
    }

    params = %{"name" => 123}
    {code, data} = Querie.Parser.parse(schema, params)
    assert code == :error
    assert Enum.find_value(data, false, fn {field, _} -> field == "name" end)
  end

  test "parse integer range by map" do
    schema = %{
      age: {:range, :integer}
    }

    params = %{"age" => %{"min" => 18, "max" => 45}}
    {code, data} = Querie.Parser.parse(schema, params)
    assert code == :ok
    assert %{filter: {:is, {:age, [18, 45]}}} = data
  end

  test "parse integer range by list" do
    schema = %{
      age: {:range, :integer}
    }

    params = %{"age" => [18, "45"]}
    {code, data} = Querie.Parser.parse(schema, params)
    assert code == :ok
    assert %{filter: {:is, {:age, [18, 45]}}} = data
  end

  test "parse integer range with default separator" do
    schema = %{
      age: {:range, :integer}
    }

    params = %{"age" => "18,45"}
    {code, data} = Querie.Parser.parse(schema, params)
    assert code == :ok
    assert %{filter: {:is, {:age, [18, 45]}}} = data
  end

  test "parse integer range with custom separator" do
    schema = %{
      age: [type: {:range, :integer}, separator: "+"]
    }

    params = %{"age" => "18+45"}
    {code, data} = Querie.Parser.parse(schema, params)
    assert code == :ok
    assert %{filter: {:is, {:age, [18, 45]}}} = data
  end

  test "parse date range with custom cast function" do
    schema = %{
      date: [
        type: {:range, :date},
        cast_func: fn value -> Timex.parse(value, "{YYYY}-{0M}-{0D}") end
      ]
    }

    params = %{"date" => "2020-10-10,2020-10-20"}
    {code, data} = Querie.Parser.parse(schema, params)
    assert code == :ok

    assert %{filter: {:is, {:date, [~N[2020-10-10 00:00:00], ~N[2020-10-20 00:00:00]]}}} = data
  end

  test "parse with custom cast function fail" do
    schema = %{
      date: [
        type: :date,
        cast_func: fn value -> Timex.parse(value, "{YYYY}-{0M}-{0D}") end
      ]
    }

    params = %{"date" => "2020-10"}
    {code, data} = Querie.Parser.parse(schema, params)
    assert code == :error
  end

  test "cast_func is not a function, fallback to default cast function" do
    schema = %{
      date: [
        type: :date,
        cast_func: "invalid function"
      ]
    }

    params = %{"date" => "2020-10-20"}
    {code, data} = Querie.Parser.parse(schema, params)
    assert code == :ok
    assert %{filter: {:is, {:date, ~D[2020-10-20]}}} = data
  end

  test "parse operator" do
    schema = %{
      age: :integer
    }

    Enum.each(~w(lt gt ge le is ne in contains icontains)a, fn op ->
      params = %{"age__#{op}" => "20"}
      {code, data} = Querie.Parser.parse(schema, params)
      assert code == :ok
      assert [%{filter: {^op, {:age, 20}}} | _] = data
    end)
  end

  test "parse ref success" do
    schema = %{
      age: :integer,
      department: [
        type: :ref,
        model: Department,
        schema: %{
          type: :string,
          name: :string,
          staff_count: :integer
        }
      ]
    }

    params = %{
      "age" => "20",
      "department__ref" => %{
        "type" => "office",
        "name__contains" => "fin",
        "staff_count__gt" => "10"
      }
    }

    {code, data} = Querie.Parser.parse(schema, params)

    assert code == :ok
  end
end
