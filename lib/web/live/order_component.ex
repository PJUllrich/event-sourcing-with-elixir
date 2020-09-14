defmodule Web.PageLive.OrderComponent do
  use Web, :live_component

  @impl true
  def render(assigns), do: Web.PageView.render("shipments.html", assigns)
end
