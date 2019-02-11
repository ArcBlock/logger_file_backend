defmodule LoggerFileBackendWithFormatters.Formatters.Default do
  @behaviour LoggerFileBackendWithFormatters.Formatter

  def format_event(level, msg, ts, md, %LoggerFileBackendWithFormatters.State{} = state) do
    metadata = LoggerFileBackendWithFormatters.take_metadata(md, state.metadata)
    Logger.Formatter.format(state.format, level, msg, ts, metadata)
  end
end
