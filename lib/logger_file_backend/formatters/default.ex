defmodule LoggerFileBackend.Formatters.Default do
  @behaviour LoggerFileBackend.Formatter

  def format_event(level, msg, ts, md, %LoggerFileBackend.State{} = state) do
    metadata = LoggerFileBackend.take_metadata(md, state.metadata)
    Logger.Formatter.format(state.format, level, msg, ts, metadata)
  end
end
