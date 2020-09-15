defmodule Web.DashboardView do
  use Web, :view

  def status(%{delivered_successfully: true}) do
    render(Web.IconView, "badge.html", color: "green", label: "Delivered", icon: "fa-check")
  end

  def status(%{delivered_successfully: false}) do
    render(Web.IconView, "badge.html",
      color: "red",
      label: "Delivery failed",
      icon: "fa-times-circle"
    )
  end

  def status(%{out_for_delivery: true}) do
    render(Web.IconView, "badge.html",
      color: "yellow",
      label: "Out for Delivery",
      icon: "fa-truck"
    )
  end

  def status(%{scheduled_for: scheduled_for}) when not is_nil(scheduled_for) do
    render(Web.IconView, "badge.html",
      color: "gray",
      label: "Scheduled",
      icon: "fa-clock"
    )
  end

  def status(_shipment) do
    render(Web.IconView, "badge.html", color: "gray", label: "Registered", icon: "fa-check")
  end
end
