defmodule Edgybot.RegistrarTest do
  @moduledoc false

  use Edgybot.RegistrarCase
  alias Edgybot.TestUtils

  setup context do
    [module_name] = TestUtils.generate_module_names(context, 1)

    defmodule module_name do
      def definitions, do: [%{id: 3}]
    end

    [module: module_name]
  end

  describe "get_module/1" do
    test "returns module with correct prefix loaded from application when definition key exists",
         %{
           registrar: registrar
         } do
      assert ^registrar = registrar.get_module({1})
    end

    test "returns nil when definition key doesn't exist", %{registrar: registrar} do
      assert nil == registrar.get_module({:none})
    end
  end

  describe "list_definitions/1" do
    test "lists definitions without duplicates", %{registrar: registrar} do
      assert [%{id: 1}, %{id: 2}] = registrar.list_definitions()
    end
  end

  describe "load_module/1" do
    test "loads module", %{registrar: registrar, module: module} do
      registrar.load_module(module)
      assert ^module = registrar.get_module({3})
    end
  end
end
