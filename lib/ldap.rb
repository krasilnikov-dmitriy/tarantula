require 'net/ldap'

class Ldap

  def self.config
    Tarantula::Application.config.ldap
  end

  def self.authenticated?(login, password)
    conn = Net::LDAP.new(
        :host       => config[:host],
        :port       => config[:port],
        :base       => config[:base],
        :encryption => :simple_tls,
        :auth       => {
            :username => "cn=#{login},#{config[:base]}",
            :password => password,
            :method   => :simple
        }
    )
    Timeout::timeout(15) do
      return conn.bind ? true : false
    end
  rescue Net::LDAP::LdapError => e
    #notify_ldap_admin(config[:host],'Error',e)
    nil
  rescue Timeout::Error => e
    #notify_ldap_admin(config[:host],'Timeout',e)
    nil
  end

  def self.authenticate(login, password)
    conn = Net::LDAP.new(
        :host       => config[:host],
        :port       => config[:port],
        :base       => config[:base],
        :encryption => :simple_tls,
        :auth       => {
            :username => "cn=#{login},#{config[:base]}",
            :password => password,
            :method   => :simple
        }
    )
    Timeout::timeout(15) do
      return conn.bind_as
    end
  rescue Net::LDAP::LdapError => e
    #notify_ldap_admin(config[:host],'Error',e)
    nil
  rescue Timeout::Error => e
    #notify_ldap_admin(config[:host],'Timeout',e)
    nil
  end

  def self.notify_ldap_admin(host,error_type,error)
    msg = "LDAP #{error_type} on #{host}"
    #RAILS_DEFAULT_LOGGER.debug(msg)
    #DeveloperMailer.deliver_ldap_failure_msg(msg,error)
  end
end
