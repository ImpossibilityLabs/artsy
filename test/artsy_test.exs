defmodule ArtsyTest do
  use ExUnit.Case
  doctest Artsy

  setup context do
    {:ok, pid} = Artsy.start_link(context.test)
    {:ok, pid: pid}
  end

  test "getting artworks with pagination and pagination reset", %{pid: pid} do
    {:ok, response_page1} = GenServer.call(pid, {:artworks})
    assert response_page1["_embedded"]

    {:ok, response_page2} = GenServer.call(pid, {:artworks})
    assert response_page2["_embedded"]
    refute response_page1 == response_page2

    :ok = GenServer.call(pid, {:artworks_reset})
    {:ok, response_page1_again} = GenServer.call(pid, {:artworks})
    assert response_page1 == response_page1_again
  end
end
