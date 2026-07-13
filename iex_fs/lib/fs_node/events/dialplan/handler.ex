defmodule FsNode.Events.Dialplan.Handler do
  import XmlBuilder

  def fetch(_tag, _key, value) do
    dialplan_for(value)
  end

  defp dialplan_for(exten) when is_binary(exten) do
    cond do
      String.match?(exten, ~r/^1\d{3}$/) ->
        user_xml(exten)

      String.match?(exten, ~r/^\d{7,}$/) ->
        outbound_xml(exten)

      true ->
        ""
    end
  end

  defp user_xml(exten) do
    generate(
      element(:extension, %{name: "user_#{exten}"}, [
        element(:condition, %{field: "destination_number", expression: "^#{exten}$"}, [
          element(:action, %{application: "bridge", data: "user/#{exten}@$${domain}"}),
        ])
      ])
    )
  end

  defp outbound_xml(exten) do
    generate(
      element(:extension, %{name: "out_#{exten}"}, [
        element(:condition, %{field: "destination_number", expression: "^(\\d+)$"}, [
          element(:action, %{application: "bridge", data: "sofia/gateway/external/\\1"}),
        ])
      ])
    )
  end
end
