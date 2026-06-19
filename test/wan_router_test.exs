defmodule WanRouterTest do
  use ExUnit.Case
  doctest WanRouter

  test "greets the world" do
    assert WanRouter.hello() == :world
  end
end
