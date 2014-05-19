class BraintreeAccount
  attr_reader :environment, :merchant_id, :public_key, :private_key

  RequiredOptions = [:environment, :merchant_id, :public_key, :private_key]

  def initialize(options)
    @environment = options[:environment]
    @merchant_id = options[:merchant_id]
    @public_key = options[:public_key]
    @private_key = options[:private_key]
  end

  def activate!
    Braintree::Configuration.environment = @environment.to_sym
    Braintree::Configuration.merchant_id = @merchant_id
    Braintree::Configuration.public_key  = @public_key
    Braintree::Configuration.private_key = @private_key
    Braintree::Configuration.logger = Logger.new("/dev/null")
  end

  def as_json
    {
      :environment => @environment,
      :merchant_id => @merchant_id,
      :public_key => @public_key,
      :private_key => @private_key
    }
  end
end
