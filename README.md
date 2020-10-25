# Querie
Query database directly from your url


## Table of content
* [What is Querie?](#what-is-querie-)
* [What Querie can do?](#what-querie-can-do-)
* [How to use Querie?](#how-to-use-querie-)
	+ [Install](#install)
	+ [Query on a single table](#query-on-a-single-table)
	+ [Sort query result](#sort-query-result)
	+ [Query `between`](#query--between-)
	+ [Query reference tables](#query-reference-tables)
	+ [Custom join field](#custom-join-field)
* [Supported operators](#supported-operators)


## What is `Querie`?
Querie is a library that help you to build the query directly from the URL parameters without  writing to much code.
If you want to add more filter criteria? Don't worry, you only need to change the filter schema.

## What `Querie` can do?
* Build Ecto Query dynamically
* Query reference tables
* Support common query operator: `>` `>=` `<` `<=` `=` `not` `like` `ilike` `between` `is_nil`
* Support sort query

**Especially Querie does not use macro** 😇

## How to use `Querie`?
### Install
Add to your `mix.exs` file:

`{:querie, "~> 0.1"}`

### Query on a single table
There are 3 steps to make it work
**1. Define a filter schema**
> Schema is a map which define:* data type of field, so it can be parsed correctly
> * which field can be filter, other extra fields are skip
> * which tables are referenced and how to query referenced tables

For example you have a Post schema:
```elixir
defmodule Example.Content.Post do
  use Ecto.Schema
  import Ecto.Changeset

  def state_enum(), do: ~w(draft published archived trash)

  schema "posts" do
    field(:content, :string)
    field(:state, :string, default: "draft")
    field(:title, :string)
    field(:view_count, :integer, default: 0)
    belongs_to(:category, Example.PostMeta.Category)
    belongs_to(:author, Example.Account.User)
  end
end
```

And you want to filter the `Post` by `title`, `state`, `view_count`. This is the schema:
```elixir
@schema %{
    title: :string,
    state: :string, # short form
    view_count: [type: :integer] # long form
}
```

**2. Parse request parameters and build the query**
Use `Querie.parse/2` to parse request parameters with your schema

```elixir
alias Example.Content.Post

def index(conn, params) do
    with {:ok, filter} <- Querie.parse(@schema, params) do
	 query = Querie.filter(Post, filter)
	 # Or you can pass a query like this
	 # query = from(p in Post, where: ....)
	 # query = Querie.filter(query, filter)
	 posts = Repo.all(query)
	 # do the rendering here
    else
    {:error, errors} ->
	 IO.puts(inspect(errors)
	 # or do anything with error
	 # error is a list of tuple {field, message}
    end
end
```

**3.  Build the  URL query**
Parameter must follow this format: `[field_name]__[operator]=[value]`. If no operator is specified, by defaut `=` operator is used.
Supported operators are listed below.

For example you want to filter `Post` which:
* `title` contains `elixir`
* `state` is `published`
* `view_count` >= 100

URL query string would be: `?title__icontains=elixir&state=published&view_count__ge=100`

### Sort query result
Follow this format to sort by field: `<field>__sort=<asc|desc>`

For example you want to sort by `title` ascending, add this to query: `title__sort=asc`

Simple, right?

### Query `between`
`Query` supports query between `min` and `max` value. It translates `between` to ` > min and < max`. And inclusive version is `ibetween` which translated to ` >= min and <= max`

You don’t have to modify your schema to use `between`.
From client you can send between value in 3 forms:
- value with separator: `view_count__between=20,60`
- array of 2 value: `view_count__between[]=20&view_count__between[]=60`
- map value with `min` and `max`: `view_count__between[min]=20&view_count__between[max]=60`

If `min` or `max` is omitted, it will use one compare operator.

### Query reference tables
For example, the `Post` schema above references to 2 other schemas: `User` and `Category` you can filter with conditions on those 2 schema.

This is the schema for `User`

```elixir
defmodule Example.Account.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:email, :string)
    field(:first_name, :string)
    field(:last_name, :string)
  end
```

**1. Update your schema**
```elixir
alias Example.Account.User

@schema %{
    title: :string,
    state: :string, 
    view_count: [type: :integer],
    author: [
		type: :ref, # this references to another schema
		model: User, # which schema to query
		schema: %{ # define filter schema for User
			email: :string
		}
	  ]
}

```

**2. Update your query**
For example you want to query `Post` by author whose `email` contains `sam` the query would be: `?author__ref[email__icontains]=sam`

### Custom join field
You can specify custom join field with 2 options:
- `foreign_key` default is `[field]_id`. In the example above, it is `author_id`
- `references` is the key to join on the other table. Default is `id`

## Supported operators
This is list of supported operators with mapping key word.

| operator | mapping keyword |
|--|--|
| = | `is` or omit |
| != | `ne` or omit |
| > | `gt` |
| >= | `ge` |
| < | `lt` |
| <= | `le` |
| like | `contains` |
| ilike | `icontains` |
| between | `between` |
| inclusive between | `ibetween` |

