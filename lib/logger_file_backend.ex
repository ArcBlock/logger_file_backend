defmodule LoggerFileBackend do
  @moduledoc """
  """

  defmodule State do
    defstruct ~w(format formatter inode io_device level metadata metadata_filter name path rotate default_meta)a
  end

  @behaviour :gen_event

  @type path :: String.t()
  @type file :: :file.io_device()
  @type inode :: File.Stat.t()
  @type format :: String.t()
  @type level :: Logger.level()
  @type metadata :: [atom]

  @default_format "$time $metadata[$level] $message\n"

  def init({__MODULE__, name}) do
    {:ok, configure(name, [])}
  end

  def handle_call({:configure, opts}, state) do
    {:ok, :ok, configure(state.name, opts, state)}
  end

  def handle_call(:path, state) do
    {:ok, {:ok, state.path}, state}
  end

  def handle_event({level, _gl, {Logger, msg, ts, md}}, state) do
    context = Keyword.merge(state.default_meta, md)

    if (is_nil(state.level) or Logger.compare_levels(level, state.level) != :lt) and
         metadata_matches?(context, state.metadata_filter) do
      log_event(level, msg, ts, md, state)
    else
      {:ok, state}
    end
  end

  def handle_event(:flush, state) do
    # We're not buffering anything so this is a no-op
    {:ok, state}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  # helpers

  defp log_event(_level, _msg, _ts, _md, %State{path: nil} = state) do
    {:ok, state}
  end

  defp log_event(level, msg, ts, md, %State{path: path, io_device: nil} = state)
       when is_binary(path) do
    case open_log(path) do
      {:ok, io_device, inode} ->
        log_event(level, msg, ts, md, %State{state | io_device: io_device, inode: inode})

      _other ->
        {:ok, state}
    end
  end

  defp log_event(
         level,
         msg,
         ts,
         md,
         %State{path: path, io_device: io_device, inode: inode} = state
       )
       when is_binary(path) do
    if !is_nil(inode) and inode == get_inode(path) and rotate(path, state.rotate) do
      output = format_event(level, msg, ts, md, state)

      try do
        IO.write(io_device, output)
        {:ok, state}
      rescue
        ErlangError ->
          case open_log(path) do
            {:ok, io_device, inode} ->
              IO.write(io_device, prune(output))
              {:ok, %State{state | io_device: io_device, inode: inode}}

            _other ->
              {:ok, %State{state | io_device: nil, inode: nil}}
          end
      end
    else
      File.close(io_device)
      log_event(level, msg, ts, md, %State{state | io_device: nil, inode: nil})
    end
  end

  defp rename_file(path, keep) do
    File.rm("#{path}.#{keep}")

    Enum.map((keep - 1)..1, fn x -> File.rename("#{path}.#{x}", "#{path}.#{x + 1}") end)

    case File.rename(path, "#{path}.1") do
      :ok -> false
      _ -> true
    end
  end

  defp rotate(path, %{max_bytes: max_bytes, keep: keep})
       when is_integer(max_bytes) and is_integer(keep) and keep > 0 do
    case File.stat(path) do
      {:ok, %{size: size}} -> if size >= max_bytes, do: rename_file(path, keep), else: true
      _ -> true
    end
  end

  defp rotate(_path, nil), do: true

  defp open_log(path) do
    case path |> Path.dirname() |> File.mkdir_p() do
      :ok ->
        case File.open(path, [:append, :utf8]) do
          {:ok, io_device} -> {:ok, io_device, get_inode(path)}
          other -> other
        end

      other ->
        other
    end
  end

  defp format_event(level, msg, ts, md, state) do
    state.formatter.format_event(level, msg, ts, md, state)
  end

  @doc false
  @spec metadata_matches?(Keyword.t(), term() | nil) :: true | false
  def metadata_matches?(_md, nil), do: true

  def metadata_matches?(md, quoted) do
    {ret, _} = Code.eval_quoted(quoted, md)
    ret
  rescue
    _ -> false
  end

  def take_metadata(metadata, :all), do: metadata

  def take_metadata(metadata, keys) do
    metadatas =
      Enum.reduce(keys, [], fn key, acc ->
        case Keyword.fetch(metadata, key) do
          {:ok, val} -> [{key, val} | acc]
          :error -> acc
        end
      end)

    Enum.reverse(metadatas)
  end

  defp get_inode(path) do
    case File.stat(path) do
      {:ok, %File.Stat{inode: inode}} -> inode
      {:error, _} -> nil
    end
  end

  defp configure(name, opts, state \\ %State{}) do
    env = Application.get_env(:logger, name, [])
    opts = Keyword.merge(env, opts)
    Application.put_env(:logger, name, opts)

    level = Keyword.get(opts, :level)
    metadata = Keyword.get(opts, :metadata, [])
    format_opts = Keyword.get(opts, :format, @default_format)
    format = Logger.Formatter.compile(format_opts)
    formatter = Keyword.get(opts, :formatter, LoggerFileBackend.Formatters.Default)
    path = Keyword.get(opts, :path)

    metadata_filter =
      opts
      |> Keyword.get(:metadata_filter, "true")
      |> Code.string_to_quoted!()

    rotate = Keyword.get(opts, :rotate)
    default_meta = Keyword.get(opts, :default_meta, [])

    %State{
      state
      | name: name,
        path: path,
        format: format,
        formatter: formatter,
        level: level,
        metadata: metadata,
        metadata_filter: metadata_filter || true,
        rotate: rotate,
        default_meta: default_meta
    }
  end

  @replacement "�"

  @spec prune(IO.chardata()) :: IO.chardata()
  def prune(binary) when is_binary(binary), do: prune_binary(binary, "")
  def prune([h | t]) when h in 0..1_114_111, do: [h | prune(t)]
  def prune([h | t]), do: [prune(h) | prune(t)]
  def prune([]), do: []
  def prune(_), do: @replacement

  defp prune_binary(<<h::utf8, t::binary>>, acc),
    do: prune_binary(t, <<acc::binary, h::utf8>>)

  defp prune_binary(<<_, t::binary>>, acc),
    do: prune_binary(t, <<acc::binary, @replacement>>)

  defp prune_binary(<<>>, acc),
    do: acc
end
