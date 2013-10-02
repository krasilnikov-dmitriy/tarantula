require 'net/ldap'

class Ldap

  def self.config
    Tarantula::Application.config.ldap
  end

  def self.authenticated?(login, password)
    conn = self.class.create_connection(login, password)
    Timeout::timeout(15) do
      return conn.bind ? true : false
    end
  rescue Net::LDAP::LdapError => e
    notify_ldap_admin(config[:host], 'Error', e)
    nil
  rescue Timeout::Error => e
    notify_ldap_admin(config[:host], 'Timeout', e)
    nil
  end

  def self.authenticate(login, password)
    conn = self.class.create_connection(login, password)
    conn.auth "#{login}@#{config[:base].scan(/dc=(?<DC>[^,]*)/).join(".")}", password
    Timeout::timeout(15) do
      result = conn.bind_as(:base => config[:base],
                       :filter => "sAMAccountName=#{login}",
                       :attributes => ["displayname", "mail"],
                       :password => password)

      if result and result.first
        user = {
            :email => result.first.mail.to_s.gsub!(/[\[\]"]/,""),
            :realname => result.first.displayName.to_s.gsub!(/[\[\]"]/,"")
        }
        return user
      else
        return false
      end
    end
  rescue Net::LDAP::LdapError => e
    notify_ldap_admin(config[:host], 'Error', e)
    nil
  rescue Timeout::Error => e
    notify_ldap_admin(config[:host], 'Timeout', e)
    nil
  end

  class << self
    private

    def self.notify_ldap_admin(host, error_type, error)
      msg = "LDAP #{error_type} on #{host}. #{error}"
      Rails.logger.error(msg)
      #DeveloperMailer.deliver_ldap_failure_msg(msg,error)
    end

    def self.create_connection(login, password)
      return Net::LDAP.new(
          :host => config[:host],
          :port => config[:port],
          :base => config[:base],
          :auth => {
              :username => "#{login}@#{config[:base].scan(/dc=(?<DC>[^,]*)/).join(".")}",
              :password => password,
              :method => :simple
          }
      )
    end
  end
end
