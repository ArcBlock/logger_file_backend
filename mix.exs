defmodule LoggerFileBackendWithFormatters.Mixfile do
  use Mix.Project

  def project do
    [
      app: :logger_file_backend_with_formatters,
      version: "0.0.1",
      elixir: "~> 1.0",
      description: description(),
      package: package(),
      deps: deps()
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
      maintainers: ["Alex Kwiatkowski"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/fremantle-capital/logger_file_backend_with_formatters"
      }
    ]
  end

  defp deps do
    [
      {:credo, "~> 0.4", only: [:dev, :test]},
      {:ex_doc, "~> 0.19", only: :dev},
      {:dialyxir, "~> 1.0.0-rc.4", only: :dev, runtime: false}
    ]
  end
end
