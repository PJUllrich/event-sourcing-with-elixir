defmodule Web.ViewHelpers do
  def time(nil), do: ""

  def time(time) when is_binary(time) do
    time
    |> Time.from_iso8601!()
    |> time()
  end

  def time(%Time{} = time) do
    time
    |> Time.truncate(:second)
    |> Time.to_string()
  end

  def icon(name, opts \\ []) do
    assigns = [name: name, class: opts[:class] || ""]
    Web.IconView.render("icon.html", assigns)
  end

  def pill(nil) do
    icon("hero-clock", class: "text-gray-400")
  end

  def pill(true) do
    icon("fa-check-circle", class: "text-green-500")
  end

  def pill(false) do
    icon("fa-times-circle", class: "text-red-500")
  end
end
