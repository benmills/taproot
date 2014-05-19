require "active_support/all"
require "braintree_account"
require "open-uri"


class ConfigManager
	attr_reader :current, :current_account

	def initialize
		@configs = {}.with_indifferent_access
		@current = nil
		@current_account = nil
	end

	def as_json
		@configs.inject({}) do |json, (name, config)|
			json[name] = config.as_json
			json
		end
	end

  def has_config?(name)
    @configs.has_key?(name)
  end

	def add(name, braintree_account_args)
		@configs[name] = BraintreeAccount.new(braintree_account_args.with_indifferent_access)
	end

	def valid?
		@configs.any?
	end

	def activate_first!
		raise "No accounts" unless valid?
		name, braintree_account = @configs.first
		activate!(name)
	end

	def activate!(name)
		@configs.fetch(name).activate!
		validate_environment!
		@current = name
		@current_account = @configs.fetch(name)
	end

  def test_environment!(name)
    original_config = current
    activate!(name)
  rescue Exception => e
    @configs.delete(name)
    raise e
  ensure
    activate!(original_config)
  end

  def validate_environment!
    old = ::OpenSSL::SSL::VERIFY_PEER
    silence_warnings{ ::OpenSSL::SSL.const_set :VERIFY_PEER, OpenSSL::SSL::VERIFY_NONE }

    binding.pry

    begin
      client_token = JSON.parse(Braintree::ClientToken.generate)
    rescue Braintree::AuthenticationError => e
      raise "Unable to authenticate to Braintree. Your keys or merchant ID may be wrong or the gateway is down."
    end

    binding.pry

    if client_token["paypal"].nil? == false
      begin
        open("#{client_token["paypal"]["baseUrl"]}/paypal")
      rescue OpenURI::HTTPError => e
        if e.message != "401 Unauthorized"
          raise e
        end
      rescue Errno::ECONNREFUSED => e
        raise "Can't connect to paypal base url #{client_token["paypal"]["baseUrl"]}"
      end
    end
  ensure
    silence_warnings{ ::OpenSSL::SSL.const_set :VERIFY_PEER, old }
	end
end
