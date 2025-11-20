defmodule See do
  @moduledoc """
  Converted from the Erlang `see` example to Elixir.
  This module preserves the original API and delegates to Erlang/OTP
  primitives where appropriate.
  """

  # Public API mirrors the original exported functions
  @spec main() :: any()
  def main do
    make_server(:io, fn -> start_io() end, &handle_io/2)
    make_server(:code, const([:lists, :error_handler, See | preloaded()]), &handle_code/2)
    make_server(:error_logger, const(0), &handle_error_logger/2)
    make_server(:halt_demon, const([]), &handle_halt_demon/2)
    make_server(:env, fn -> start_env() end, &handle_env/2)
    mod = get_module_name()
    load_module(mod)
    run(mod)
  end

  defp run(mod) do
    pid = spawn_link(mod, :main, [])
    on_exit(pid, fn why -> stop_system(why) end)
  end

  def load_module(mod), do: rpc(:code, {:load, mod})
  def modules_loaded(), do: rpc(:code, :modules_loaded)

  def handle_code(:modules_loaded, mods), do: {length(mods), mods}

  def handle_code({:load, mod}, mods) do
    if :lists.member(mod, mods) do
      {:already_loaded, mods}
    else
      case prim_load(mod) do
        {:ok, ^mod} -> {{:ok, mod}, [mod | mods]}
        error -> {error, mods}
      end
    end
  end

  defp prim_load(module) do
    str = Atom.to_charlist(module)

    case :erl_prim_loader.get_file(str ++ ~c".beam") do
      {:ok, bin, _full} ->
        case :erlang.load_module(module, bin) do
          {:module, ^module} -> {:ok, module}
          {:module, _} -> {:error, :wrong_module_in_binary}
          _ -> {:error, {:bad_object_code, module}}
        end

      _ ->
        {:error, {:cannot_locate, module}}
    end
  end

  def log_error(error), do: cast(:error_logger, {:log, error})

  def handle_error_logger({:log, error}, n) do
    :erlang.display({:error, error})
    {:ok, n + 1}
  end

  def on_halt(fun), do: cast(:halt_demon, {:on_halt, fun})
  def stop_system(why), do: cast(:halt_demon, {:stop_system, why})

  def handle_halt_demon({:on_halt, fun}, funs), do: {:ok, [fun | funs]}

  def handle_halt_demon({:stop_system, why}, funs) do
    case why do
      :normal -> true
      _ -> :erlang.display({:stopping_system, why})
    end

    :lists.map(fn f -> f.() end, funs)
    :erlang.halt()
    {:ok, []}
  end

  def read(), do: rpc(:io, :read)
  def write(x), do: rpc(:io, {:write, x})

  def start_io do
    port = Port.open({:fd, 0, 1}, [:eof, :binary])
    Process.flag(:trap_exit, true)
    {false, port}
  end

  def handle_io(:read, {true, port}), do: {:eof, {true, port}}

  def handle_io(:read, {false, port}) do
    receive do
      {^port, {:data, bytes}} -> {{:ok, bytes}, {false, port}}
      {^port, :eof} -> {:eof, {true, port}}
      {:EXIT, ^port, :badsig} -> handle_io(:read, {false, port})
      {:EXIT, ^port, _why} -> {:eof, {true, port}}
    end
  end

  def handle_io({:write, x}, {flag, port}) do
    send(port, {self(), {:command, x}})
    {:ok, {flag, port}}
  end

  def env(key), do: rpc(:env, {:lookup, key})

  def handle_env({:lookup, key}, dict), do: {lookup(key, dict), dict}

  def start_env do
    env =
      case :init.get_argument(:environment) do
        {:ok, [l]} -> l
        :error -> fatal({:missing, ~c"-environment ..."})
      end

    :lists.map(&split_env/1, env)
  end

  defp split_env(str), do: split_env(str, [])

  defp split_env([?$ = _ | t], l), do: {:lists.reverse(l), t}
  defp split_env([], l), do: {:lists.reverse(l), []}
  defp split_env([h | t], l), do: split_env(t, [h | l])

  def make_server(name, fun_d, fun_h) do
    make_global(name, fn ->
      data = fun_d.()
      server_loop(name, data, fun_h)
    end)
  end

  defp server_loop(name, data, fun) do
    receive do
      {:rpc, pid, q} ->
        case safe_call(fun, q, data) do
          {:EXIT, why} ->
            send(pid, {name, :exit, why})
            server_loop(name, data, fun)

          {:ok, {reply, data1}} ->
            send(pid, {name, reply})
            server_loop(name, data1, fun)
        end

      {:cast, pid, q} ->
        case safe_call(fun, q, data) do
          {:EXIT, why} ->
            :erlang.exit(pid, why)
            server_loop(name, data, fun)

          {:ok, data1} ->
            server_loop(name, data1, fun)
        end

      {:eval, fun1} ->
        server_loop(name, data, fun1)
    end
  end

  defp safe_call(fun, q, data) do
    try do
      {:ok, fun.(q, data)}
    catch
      :exit, why -> {:EXIT, why}
      :error, why -> {:EXIT, why}
      :throw, why -> {:EXIT, why}
    end
  end

  def rpc(name, q) do
    send(name, {:rpc, self(), q})

    receive do
      {^name, reply} -> reply
      {^name, :exit, why} -> exit(why)
    end
  end

  def cast(name, q), do: send(name, {:cast, self(), q})

  def change_behaviour(name, fun), do: send(name, {:eval, fun})

  def const(c), do: fn -> c end

  def keep_alive(name, fun) do
    pid = make_global(name, fun)
    on_exit(pid, fn _exit -> keep_alive(name, fun) end)
  end

  def make_global(name, fun) do
    case :erlang.whereis(name) do
      :undefined ->
        self_pid = self()
        pid = spawn(fn -> make_global(self_pid, name, fun) end)

        receive do
          {^pid, :ack} -> pid
        end

      pid ->
        pid
    end
  end

  defp make_global(pid, name, fun) do
    # Try to register this process under name
    case :erlang.register(name, self()) do
      {:EXIT, _} ->
        send(pid, {self(), :ack})

      _ ->
        send(pid, {self(), :ack})
        fun.()
    end
  end

  def on_exit(pid, fun) do
    spawn(fn ->
      :erlang.process_flag(:trap_exit, true)
      :erlang.link(pid)

      receive do
        {:EXIT, ^pid, why} -> fun.(why)
      end
    end)
  end

  def every(pid, time, fun) do
    spawn(fn ->
      :erlang.process_flag(:trap_exit, true)
      :erlang.link(pid)
      every_loop(pid, time, fun)
    end)
  end

  defp every_loop(pid, time, fun) do
    receive do
      {:EXIT, ^pid, _why} -> true
    after
      time ->
        fun.()
        every_loop(pid, time, fun)
    end
  end

  def get_module_name do
    case :init.get_argument(:load) do
      {:ok, [[arg]]} -> module_name(arg)
      :error -> fatal({:missing, ~c"-load Mod"})
    end
  end

  def lookup(key, l) do
    case :lists.keysearch(key, 1, l) do
      {:value, t} -> {:found, elem(t, 1)}
      false -> :not_found
    end
  end

  defp module_name(str) do
    try do
      :erlang.list_to_atom(str)
    rescue
      _ ->
        log_error({:bad_module_name, str})
        stop_system(:bad_start_module)
    end
  end

  def fatal(term) do
    log_error({:fatal, term})
    stop_system({:fatal, term})
  end

  def preloaded() do
    [:zlib, :prim_file, :prim_zip, :prim_inet, :erlang, :otp_ring0, :init, :erl_prim_loader]
  end

  def make_scripts() do
    {:ok, cwd} = :file.get_cwd()

    script =
      {:script, {~c"see", ~c"1.0"},
       [
         {:preLoaded, preloaded()},
         {:progress, :preloaded},
         {:path, [cwd]},
         {:primLoad, [:lists, :error_handler, See]},
         {:progress, :kernel_load_completed},
         {:progress, :started},
         {:apply, {See, :main, []}}
       ]}

    :io.format(~c"Script:~p~n", [script])

    :file.write_file(~c"see.boot", :erlang.term_to_binary(script))

    :file.write_file(
      ~c"see",
      ~c"#!/bin/sh\nerl -boot " ++ cwd ++ ~c"/see -environment `printenv` -load $1\n"
    )

    :os.cmd(~c"chmod a+x see")
    :init.stop()
    true
  end
end
