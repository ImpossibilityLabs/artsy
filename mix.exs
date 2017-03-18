defmodule Artsy.Mixfile do
  use Mix.Project

  def project do
    [app: :artsy,
     version: "0.1.1",
     elixir: "~> 1.4",
     description: "Wrapper to use Artsy API to get artworks.",
     docs: [extras: ["README.md"]],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package(),
     deps: deps()]
  end

  def package do
    [ 
      name: :artsy,
      files: ["lib", "mix.exs"],
      maintainers: ["Vyacheslav Voronchuk"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/ImpossibilityLabs/artsy"},
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [
      extra_applications: [
        :logger,
        :httpoison
      ],
      mod: {Artsy, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:hackney, "1.6.1"},
      {:httpoison, "~> 0.9.2"},
      {:poison, "~> 2.0"},
      {:uuid, "~> 1.1"},
      {:earmark, ">= 0.0.0", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev},
    ]
  end
end
