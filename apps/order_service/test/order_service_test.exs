defmodule OrderServiceTest do
  use ExUnit.Case
  doctest OrderService

  test "greets the world" do
    assert OrderService.hello() == :world
  end
end
