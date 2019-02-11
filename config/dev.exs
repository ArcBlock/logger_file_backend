use Mix.Config

config :logger,
  backends: [{LoggerFileBackendWithFormatters, :dev_backend}],
  level: :info,
  format: "$time $metadata[$level] $message\n"

config :logger, :dev_backend,
  level: :error,
  path: "test/logs/error.log",
  format: "DEV $message"
