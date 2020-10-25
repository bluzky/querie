# Querie
Query database directly from your url

## What is Querie?
Querie is a library that help you to build the query directly from the URL parameters without  writing to much code. 
If you want to add more filter criteria? Don't worry, you only need to change the filter schema.

## What Querie can do?
- Build Ecto Query dynamically
- Query reference tables
- Support common query operator: `>` `>=` `<` `<=` `=` `not` `like` `ilike` `between` `is_nil`
- Support sort query

**Especially Querie does not use macro** 😇


## How to use Querie?

### Query on a single table

There are 3 steps to make it work
**1. Define a filter schema**
> Schema is a map which define:
> - data type of field, so it can be parsed correctly
> - which field can be filter, other extra fields are skip
> - which tables are referenced and how to query referenced tables

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
    timestamps()
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
Parameter must follow this format: `<field_name>__<operator>=<value>`. If no operator is specified, by defaut `=` operator is used.
Supported operators are listed above.

For example you want to filter `Post` which:
- `title` contains `elixir`
- `state` is `published`
- `view_count` >= 100

URL query string would be: `?title__icontains=elixir&state=published&view_count__ge=100` 

### Supported operators
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
| between | `between |
| ibetween | `ibetween` |


### Query join tables
