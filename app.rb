require "sinatra"
require "braintree"
require "json"
require "base64"
require "pry"

# Mark's test prod aaccount
# Braintree::Configuration.environment = :production
# Braintree::Configuration.merchant_id = 'nxtmb3rqt8tr35v2'
# Braintree::Configuration.public_key = 'b2kqymfxnhx7wdtz'
# Braintree::Configuration.private_key = '8f00a7a5df9541ec05f2fa8e1b333f29'

# Ben's test prod account
Braintree::Configuration.environment = :production
Braintree::Configuration.merchant_id = 'dnnsn36rs57sqvym'
Braintree::Configuration.public_key = 'pkcp77fk7m52gx3t'
Braintree::Configuration.private_key = '9a37eb11d451554bfeece5f20ec1cf35'

# Braintree::Configuration.environment = :sandbox
# Braintree::Configuration.merchant_id = 'qh5bmbx4v6pzw93h'
# Braintree::Configuration.public_key = '4fmd3mrwgc9bdvkh'
# Braintree::Configuration.private_key = 'd3af2d01d2828a068eca39455f864d1e'

get "/client_token.json" do
  content_type :json

  {
    :client_token => Braintree::ClientToken.generate
  }.to_json
end

get "/client_token/inspect" do
  content_type :json
  JSON.pretty_generate(JSON.parse(Base64.decode64(Braintree::ClientToken.generate)))
end

get "/dropin" do
  @client_token = Braintree::ClientToken.generate
  erb :dropin
end

get "/custom" do
  @client_token = Braintree::ClientToken.generate
  erb :custom
end

post "/transaction" do
  # result = Braintree::Customer.create(:payment_method_nonce => params[:payment_method_nonce])
  # # token = result.customer.paypal_accounts.first.token
  # # result = Braintree::Transaction.sale(:amount => 1, :payment_method_token => token)

  # binding.pry

  p params

  content_type :text
  params.inspect
end
