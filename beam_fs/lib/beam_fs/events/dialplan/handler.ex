defmodule BeamFs.Events.Dialplan.Handler do
  import XmlBuilder

  def fetch(_tag, _key, _value, params) do
    dest = get_param(params, "Caller-Destination-Number")
    dialplan_for(dest)
  end

  defp get_param(params, key) do
    case List.keyfind(params, key, 0) do
      {^key, val} -> to_string(val)
      nil -> ""
    end
  end

  defp dialplan_for(exten) when is_binary(exten) do
    cond do
      String.match?(exten, ~r/^1\d{3}$/) ->
        user_xml(exten)

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
end
