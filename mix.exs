defmodule Redis.MixProject do
  use Mix.Project

  def project do
    [
      app: :redis,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod
    ]
  end

  def application do
    [
      mod: {Redis.Application, []},
      extra_applications: [:logger]
    ]
  end
end
