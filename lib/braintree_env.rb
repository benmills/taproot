class BraintreeEnvironment
  attr_reader :nickname, :options

  def initialize(nickname, options)
    @nickname = nickname
    @options = options
  end

  def activate!
    Braintree::Configuration.environment = @options[:environment].to_sym
    Braintree::Configuration.merchant_id = @options[:merchant_id]
    Braintree::Configuration.public_key = @options[:public_key]
    Braintree::Configuration.private_key = @options[:private_key]
  end
end
