defmodule LoggerFileBackendWithFormatters.Formatter do
  @moduledoc """
  Behaviour that should be implemented by log formatters.
  """

  @callback format_event(
              level :: Logger.level(),
              msg :: Logger.message(),
              ts :: Logger.Formatter.time(),
              md :: [atom] | :all,
              state :: Map.t()
            ) :: Map.t() | iodata()
end
