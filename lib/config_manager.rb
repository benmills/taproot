class ConfigManager
	attr_reader :current, :current_account

	def initialize
		@configs = {}
		@current = nil
		@current_account = nil
	end

	def as_json
		@configs.inject({}) do |json, (name, config)|
			json[name] = config.as_json
			json
		end
	end

	def add(name, braintree_account_args)
		@configs[name] = BraintreeAccount.new(braintree_account_args)
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

  def validate_environment!
		_validate_gateway_is_up!
		_validate_client_token!
  end

	def _validate_gateway_is_up!
    begin
      open("#{Braintree::Configuration.instantiate.base_merchant_url}/ping")
    rescue Errno::ECONNREFUSED => e
      raise "Gateway is down for url #{Braintree::Configuration.instantiate.base_merchant_url}/ping"
    rescue Errno::ENOENT => e
      raise "Gateway is down for url #{Braintree::Configuration.instantiate.base_merchant_url}/ping"
    end
	end

	def _validate_client_token!
    begin
      client_token = JSON.parse(Braintree::ClientToken.generate)
    rescue Braintree::AuthenticationError => e
      raise "Unable to authenticate to Braintree. Your keys or merchant ID may be wrong."
    end

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
	end
end
