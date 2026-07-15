defmodule BeamFs.Debug do
  def run do
    IO.puts("\n========== beam_fs diagnostics ==========\n")

    # 1. node info
    IO.puts("1. local node: #{node()}")
    IO.puts("   cookie: #{:erlang.get_cookie()}")

    # 2. connection
    IO.puts("\n2. connection connected?: #{BeamFs.Lib.Connection.connected?()}")
    IO.puts("   connected nodes: #{inspect(BeamFs.Lib.Connection.connected_nodes())}")

    # 3. config
    fs_config = Application.get_env(:beam_fs, :freeswitch, [])
    IO.puts("\n3. freeswitch config: #{inspect(fs_config)}")

    sip_config = Application.get_env(:beam_fs, :sip, [])
    IO.puts("   sip users: #{length(sip_config[:users] || [])}")

    for u <- sip_config[:users] || [] do
      IO.puts("     - #{u[:username]} / #{u[:password]} / #{u[:domain]}")
    end

    # 4. test directory fetch
    IO.puts("\n4. test directory fetch for '1000':")
    result = BeamFs.Events.Directory.Handler.fetch(:id, :"caller-id-number", "1000", [])

    if result == "" do
      IO.puts("   RESULT: empty - user NOT found!")
    else
      IO.puts("   RESULT: xml returned (#{byte_size(result)} bytes) - user FOUND")
      IO.puts("   first 200 chars: #{String.slice(result, 0, 200)}")
    end

    # 5. test api to fs
    IO.puts("\n5. test api to fs:")

    case BeamFs.Lib.Api.status() do
      {:ok, status} ->
        first_line = status |> String.split("\n") |> List.first()
        IO.puts("   status: #{first_line}")

      {:error, reason} ->
        IO.puts("   ERROR: #{inspect(reason)}")
    end

    # 6. check fs registered processes
    IO.puts("\n6. checking fs node processes...")

    case :rpc.call(:"fs@10.0.2.1", :erlang, :whereis, [:fs]) do
      {:badrpc, reason} ->
        IO.puts("   rpc not supported: #{inspect(reason)}")
        IO.puts("   (this is normal for mod_erlang_event)")

      pid ->
        IO.puts("   :fs process: #{inspect(pid)}")
    end

    # 7. try to send a direct message to fs
    IO.puts("\n7. direct erlang message test...")
    send({:fs, :"fs@10.0.2.1"}, {:api, :status, ""})

    receive do
      {:ok, result} ->
        first_line = result |> String.split("\n") |> List.first()
        IO.puts("   direct api result: #{first_line}")

      {:error, reason} ->
        IO.puts("   direct api error: #{inspect(reason)}")
    after
      5_000 ->
        IO.puts("   TIMEOUT - no response from fs@10.0.2.1")
    end

    IO.puts("\n========== diagnostics complete ==========")
  end
end
