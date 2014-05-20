require "active_support/all"
require "braintree_account"
require "open-uri"
require "timeout"


class ConfigManager
	attr_reader :current, :current_account, :current_merchant_account
  attr_accessor :current_merchant_account, :masked

	def initialize
    @masked = false
		@configs = {}.with_indifferent_access
		@current = nil
		@current_account = nil
    @current_merchant_account = nil
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
    @configs[name].masked = @masked
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

    puts "--- [#{current}] Getting client token for validation of environment"
    begin
      client_token = JSON.parse(Braintree::ClientToken.generate)
    rescue Errno::ECONNRESET => e
      return "The gateway is down for URL #{Braintree::Configuration.instantiate.base_merchant_url}"
    rescue Braintree::AuthenticationError => e
      return "Unable to authenticate to Braintree while getteing client token. Your keys or merchant ID may be wrong or the gateway is down."
    end

    if client_token["paypal"].nil? == false
      puts "--- [#{current}] Trying to connect to paypal"
      begin
        Timeout::timeout(5) { open("#{client_token["paypal"]["baseUrl"]}/paypal") }
      rescue OpenURI::HTTPError => e
        if e.message != "401 Unauthorized"
          return "Error opening #{"#{client_token["paypal"]["baseUrl"]}/paypal"}: #{e.message}"
        end
      rescue Errno::ECONNREFUSED => e
        return "Can't connect to paypal base url #{client_token["paypal"]["baseUrl"]}"
      end
    end

    "Valid"
  rescue Timeout::Error => e
    "Timed out connecting to paypal at #{"#{client_token["paypal"]["baseUrl"]}/paypal"}"
  ensure
    silence_warnings{ ::OpenSSL::SSL.const_set :VERIFY_PEER, old }
	end
end
