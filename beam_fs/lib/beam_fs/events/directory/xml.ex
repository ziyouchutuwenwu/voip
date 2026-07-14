defmodule BeamFs.Events.Directory.Xml do
  import XmlBuilder

  def domain(domain_name, users) do
    dial_string = "{^^:sip_invite_domain=${dialed_domain}:presence_id=${dialed_user}@${dialed_domain}}${sofia_contact(*/${dialed_user}@${dialed_domain})},${verto_contact(${dialed_user}@${dialed_domain})}"

    generate(
      element(:document, %{type: "freeswitch/xml"}, [
        element(:section, %{name: "directory"}, [
          element(:domain, %{name: domain_name}, [
            element(:params, nil, [
              element(:param, %{name: "dial-string", value: dial_string}),
            ])
          ] ++ Enum.map(users, fn u ->
            user_element(u[:username], u[:password], u[:domain] || domain_name)
          end))
        ])
      ])
    )
  end

  defp user_element(username, password, _domain) do
    element(:user, %{id: username}, [
      element(:params, nil, [
        element(:param, %{name: "password", value: password}),
        element(:param, %{name: "vm-enabled", value: false}),
        element(:param, %{name: "vm-password", value: password}),
      ]),
      element(:variables, nil, [
        element(:variable, %{name: "user_context", value: "default"}),
        element(:variable, %{name: "effective_caller_id_name", value: "extension #{username}"}),
        element(:variable, %{name: "effective_caller_id_number", value: username}),
      ])
    ])
  end

  def user(username, domain, password, opts \\ []) do
    vm_password = Keyword.get(opts, :vm_password, password)
    vm_enabled = Keyword.get(opts, :vm_enabled, false)
    caller_id_name = Keyword.get(opts, :caller_id_name, "extension #{username}")
    caller_id_number = Keyword.get(opts, :caller_id_number, username)

    dial_string = "{^^:sip_invite_domain=${dialed_domain}:presence_id=${dialed_user}@${dialed_domain}}${sofia_contact(*/${dialed_user}@${dialed_domain})},${verto_contact(${dialed_user}@${dialed_domain})}"

    generate(
      element(:document, %{type: "freeswitch/xml"}, [
        element(:section, %{name: "directory"}, [
          element(:domain, %{name: domain}, [
            element(:params, nil, [
              element(:param, %{name: "dial-string", value: dial_string}),
            ]),
            element(:user, %{id: username}, [
              element(:params, nil, [
                element(:param, %{name: "password", value: password}),
                element(:param, %{name: "vm-enabled", value: vm_enabled}),
                element(:param, %{name: "vm-password", value: vm_password}),
              ]),
              element(:variables, nil, [
                element(:variable, %{name: "user_context", value: "default"}),
                element(:variable, %{name: "effective_caller_id_name", value: caller_id_name}),
                element(:variable, %{name: "effective_caller_id_number", value: caller_id_number}),
              ])
            ])
          ])
        ])
      ])
    )
  end
end
