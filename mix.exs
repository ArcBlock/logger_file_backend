defmodule LoggerFileBackend.Mixfile do
  use Mix.Project

  @top File.cwd!()

  @version @top |> Path.join("version") |> File.read!() |> String.trim()
  @elixir_version @top |> Path.join(".elixir_version") |> File.read!() |> String.trim()

  def project do
    [
      app: :logger_file_backend,
      version: @version,
      elixir: @elixir_version,
      description: description(),
      package: package(),
      deps: deps(),
      dialyzer: [ignore_warnings: ".dialyzer_ignore.exs", plt_add_apps: []]
    ]
  end

  def application do
    [applications: []]
  end

  defp description do
    "Simple logger backend that writes to a file"
  end

  defp package do
    [
      maintainers: ["Tyr Chen"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/tyrchen/logger_file_backend"
      }
    ]
  end

  defp deps do
    [
      # dev and test
      {:credo, "~> 1.0.0", only: [:dev, :test]},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.19.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: [:test]},
      {:pre_commit_hook, "~> 1.2", only: [:dev, :test], runtime: false}
    ]
  end
end
