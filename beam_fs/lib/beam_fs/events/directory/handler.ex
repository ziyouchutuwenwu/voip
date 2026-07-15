defmodule BeamFs.Events.Directory.Handler do
  require Logger
  alias BeamFs.Events.Directory.Xml
  alias BeamFs.SipUser

  def fetch(tag, _key, value, _params) when tag in ~w(domain) do
    domain = value
    users = SipUser.list_all()
    result = Xml.domain(domain, users)
    Logger.info("directory domain fetch: #{value} -> using domain #{domain} with #{length(users)} users (#{byte_size(result)} bytes)")
    result
  end

  def fetch(tag, key, value, _params) do
    Logger.info("directory fetch: tag=#{inspect(tag)} key=#{inspect(key)} value=#{inspect(value)}")
    user = SipUser.find_by_username(value)

    result =
      case user do
        nil ->
          Logger.warning("user not found: #{value}")
          ""

        user ->
          Logger.info("user found: #{user[:username]}, generating xml")
          domain = user[:domain] || "10.0.2.222"
          Xml.user(user[:username], domain, user[:password])
      end

    Logger.info("directory fetch response length: #{byte_size(result)}")
    result
  end
end
