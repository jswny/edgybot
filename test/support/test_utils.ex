defmodule Edgybot.TestUtils do
  @moduledoc false

  def generate_module_names(%{module: module, test: test}, num_module_names)
      when is_atom(module) and is_atom(test) and is_integer(num_module_names) do
    generate_module_names([module, test], num_module_names)
  end

  def generate_module_names(prefixes, num_module_names)
      when is_list(prefixes) and is_integer(num_module_names) do
    Enum.map(1..num_module_names, fn num ->
      prefixes
      |> Enum.concat([TestModule, inspect(num)])
      |> List.flatten()
      |> Enum.map(&convert_to_module_form/1)
      |> Module.concat()
    end)
  end

  def random_number, do: random_number_with_max(1_000_000)

  def random_string, do: random_string_with_length(10)

  defp random_number_with_max(max) do
    :rand.uniform(max)
  end

  defp random_string_with_length(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64()
  end

  defp convert_to_module_form(piece) when is_atom(piece) or is_binary(piece) do
    case is_atom(piece) do
      true -> Atom.to_string(piece)
      false -> piece
    end
    |> String.replace(~r/[^A-Za-z0-9_.]/, "_")
  end
end
