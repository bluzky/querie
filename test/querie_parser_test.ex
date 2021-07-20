defmodule QuerieParserTest do
  use ExUnit.Case
  doctest Querie

  test "parse string" do
    schema = %{
      name: :string
    }

    params = %{"name" => "dzung"}
    {code, data} = Querie.Parser.parse(schema, params)
    assert code == :ok
    assert [{:name, {:is, "dzung"}} | _] = data
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
    assert [{:age, {:is, [18, 45]}} | _] = data
  end

  test "parse integer range by list" do
    schema = %{
      age: {:range, :integer}
    }

    params = %{"age" => [18, "45"]}
    {code, data} = Querie.Parser.parse(schema, params)
    assert code == :ok
    assert [{:age, {:is, [18, 45]}} | _] = data
  end

  test "parse integer range with default separator" do
    schema = %{
      age: {:range, :integer}
    }

    params = %{"age" => "18,45"}
    {code, data} = Querie.Parser.parse(schema, params)
    assert code == :ok
    assert [{:age, {:is, [18, 45]}} | _] = data
  end

  test "parse integer range with custom separator" do
    schema = %{
      age: [type: {:range, :integer}, separator: "+"]
    }

    params = %{"age" => "18+45"}
    {code, data} = Querie.Parser.parse(schema, params)
    assert code == :ok
    assert [{:age, {:is, [18, 45]}} | _] = data
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

    assert [{:date, {:is, [~N[2020-10-10 00:00:00], ~N[2020-10-20 00:00:00]]}} | _] = data
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
    assert [{:date, {:is, ~D[2020-10-20]}} | _] = data
  end

  test "parse operator" do
    schema = %{
      age: :integer
    }

    Enum.each(~w(lt gt ge le is ne in contains icontains)a, fn op ->
      params = %{"age__#{op}" => "20"}
      {code, data} = Querie.Parser.parse(schema, params)
      assert code == :ok
      assert [{:age, {^op, 20}} | _] = data
    end)
  end

  test "parse sort" do
    schema = %{
      age: :integer
    }

    params = %{"age__sort" => "asc"}
    {code, data} = Querie.Parser.parse(schema, params)
    assert code == :ok
    assert [{:_sort, [{:age, :asc} | _]}] = data
  end

  test "parse sort with priority" do
    schema = %{
      age: [type: :integer, sort_priority: 2],
      salary: [type: :integer, sort_priority: 1]
    }

    params = %{"age__sort" => "asc", "salary__sort" => "desc"}
    {code, data} = Querie.Parser.parse(schema, params)
    assert code == :ok
    assert [{:_sort, [{:salary, :desc}, {:age, :asc}]}] = data
  end

  test "parse sort with default" do
    schema = %{
      age: [type: :integer, sort_priority: 2],
      salary: [type: :integer, sort_priority: 1, sort_default: :asc]
    }

    params = %{"age__sort" => "asc"}
    {code, data} = Querie.Parser.parse(schema, params)
    assert code == :ok
    assert [{:_sort, [{:salary, :asc}, {:age, :asc}]}] = data
  end

  test "parse sort override default" do
    schema = %{
      age: [type: :integer, default_sort: :desc]
    }

    params = %{"age__sort" => "asc"}
    {code, data} = Querie.Parser.parse(schema, params)
    assert code == :ok
    assert [{:_sort, [{:age, :asc}]}] = data
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
    department = Keyword.get(data, :department)
    age = Keyword.get(data, :age)

    assert code == :ok
    assert age = {:is, 20}

    assert department =
             {:ref,
              {Department,
               [
                 {:type, {:is, "office"}},
                 {:name, {:contains, "fin"}},
                 {:staff_count, {:gt, 10}},
                 {:_sort, []}
               ]}}
  end
end
