defmodule Querie.MixProject do
  use Mix.Project

  def project do
    [
      app: :querie,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      name: "Querie",
      description: description(),
      source_url: "https://github.com/bluzky/tarams",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package() do
    [
      maintainers: ["Dung Nguyen"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/bluzky/querie"}
    ]
  end

  defp description() do
    "Query database directly from URL"
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.0"},
      {:timex, "~> 3.5", only: [:test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
