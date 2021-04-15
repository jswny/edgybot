defmodule Edgybot.Meta.Snowflake do
  @moduledoc false

  import Ecto.Changeset
  require Nostrum.Snowflake

  def validate_snowflake(changeset, field) when is_atom(field) and is_map(changeset) do
    validate_change(changeset, field, fn _current_field, value ->
      if is_snowflake?(value) do
        []
      else
        [{field, "invalid snowflake"}]
      end
    end)
  end

  defp is_snowflake?(value) when is_binary(value) do
    value
    |> String.to_integer()
    |> is_snowflake?()
  end

  defp is_snowflake?(value) when is_integer(value), do: Nostrum.Snowflake.is_snowflake(value)
end
