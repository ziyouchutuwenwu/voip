defmodule FsNodeWeb.Sip.DirectoryXml do
  import XmlBuilder

  def network_list do
    generate(
      doc_el("freeswitch/xml", [
        section_el("directory", [
          element(:list)
        ])
      ])
    )
  end

  def domain(domain_name) do
    generate(
      doc_el("freeswitch/xml", [
        section_el("directory", [
          element(:domain, %{name: domain_name}, [
            element(:params, nil, [
              element(:param, %{name: "dial-string", value: "{^^:sip_invite_domain=${dialed_domain}:presence_id=${dialed_user}@${dialed_domain}}${sofia_contact(*/${dialed_user}@${dialed_domain})},${verto_contact(${dialed_user}@${dialed_domain})}"}),
            ]),
            element(:variables, nil, [
              element(:variable, %{name: "user_context", value: "default"}),
            ])
          ])
        ])
      ])
    )
  end

  def user(user, opts \\ []) do
    wrap_doc = Keyword.get(opts, :wrap_doc, false)
    dial_string = "{^^:sip_invite_domain=${dialed_domain}:presence_id=${dialed_user}@${dialed_domain}}${sofia_contact(*/${dialed_user}@${dialed_domain})},${verto_contact(${dialed_user}@${dialed_domain})}"

    user_xml = [
      element(:user, %{id: user.username}, [
        element(:params, nil, [
          element(:param, %{name: "password", value: user.password}),
          element(:param, %{name: "vm-enabled", value: user.vm_enabled}),
          element(:param, %{name: "vm-password", value: user.vm_password || user.password}),
          element(:param, %{name: "dial-string", value: dial_string}),
        ]),
        element(:variables, nil, [
          element(:variable, %{name: "user_context", value: "default"}),
          element(:variable, %{name: "effective_caller_id_name", value: user.caller_id_name || "Extension #{user.username}"}),
          element(:variable, %{name: "effective_caller_id_number", value: user.caller_id_number || user.username}),
        ])
      ])
    ]

    if wrap_doc do
      generate(
        doc_el("freeswitch/xml", [
          section_el("directory", [
            element(:domain, %{name: user.domain}, user_xml)
          ])
        ])
      )
    else
      generate(user_xml)
    end
  end

  def user(username, domain, password, opts \\ []) do
    vm_password = Keyword.get(opts, :vm_password, password)
    vm_enabled = Keyword.get(opts, :vm_enabled, false)
    caller_id_name = Keyword.get(opts, :caller_id_name, "Extension #{username}")
    caller_id_number = Keyword.get(opts, :caller_id_number, username)

    dial_string = "{^^:sip_invite_domain=${dialed_domain}:presence_id=${dialed_user}@${dialed_domain}}${sofia_contact(*/${dialed_user}@${dialed_domain})},${verto_contact(${dialed_user}@${dialed_domain})}"

    generate(
      doc_el("freeswitch/xml", [
        section_el("directory", [
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

  defp doc_el(type, children) do
    element(:document, %{type: type}, children)
  end

  defp section_el(name, children) do
    element(:section, %{name: name}, children)
  end
end
