defmodule EdgybotTest do
  use ExUnit.Case
  doctest Edgybot

  test "greets the world" do
    assert Edgybot.hello() == :world
  end
end
