defmodule Edgybot.RegistrarTest do
  @moduledoc false

  use ExUnit.Case

  alias Edgybot.Config

  describe "runtime_env" do
    test "gets runtime environment from application environment" do
      assert :test == Config.runtime_env()
    end
  end
end
