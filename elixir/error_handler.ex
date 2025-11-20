defmodule :error_handler do
  def undefined_function(:see, f, a) do
    :erlang.display({:error_handler, :undefined_function, :see, f, a})
    :erlang.exit(:oops)
  end

  def undefined_function(m, f, a) do
    :erlang.display({:new_error_handler, :undefined_function, m, f, a})

    case See.load_module(m) do
      {:ok, m} ->
        case :erlang.function_exported(m, f, length(a)) do
          true ->
            :erlang.display({:error_handler, :calling, m, f, a})
            apply(m, f, a)

          false ->
            See.stop_system({:undef, {m, f, a}})
        end

      {:ok, _other} ->
        See.stop_system({:undef, {m, f, a}})

      :already_loaded ->
        See.stop_system({:undef, {m, f, a}})

      {:error, what} ->
        See.stop_system({:load, :error, what})
    end
  end

  def undefined_global_name(name, message) do
    :erlang.exit({:badarg, {name, message}})
  end
end
