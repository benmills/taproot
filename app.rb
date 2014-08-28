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

# Mark's test prod aaccount
# Braintree::Configuration.environment = :production
# Braintree::Configuration.merchant_id = '8ghb7q247srxc8cf'
# Braintree::Configuration.public_key = '9n7p3vh9pfg8zvh2'
# Braintree::Configuration.private_key = '8cec496e161abeae7a96d8ed2625c8f0'

# Stubhub
Braintree::Configuration.environment = :production
Braintree::Configuration.merchant_id = 'pm585nc2457zpw2w'
Braintree::Configuration.public_key = 'wmckxcq3zpyc5rwf'
Braintree::Configuration.private_key = 'c751bdf919486d6b083b82b80b183f1d'

# Ben's test prod account
# Braintree::Configuration.environment = :production
# Braintree::Configuration.merchant_id = 'dnnsn36rs57sqvym'
# Braintree::Configuration.public_key = 'pkcp77fk7m52gx3t'
# Braintree::Configuration.private_key = '9a37eb11d451554bfeece5f20ec1cf35'

# Braintree::Configuration.environment = :sandbox
# Braintree::Configuration.merchant_id = 'qh5bmbx4v6pzw93h'
# Braintree::Configuration.public_key = '4fmd3mrwgc9bdvkh'
# Braintree::Configuration.private_key = 'd3af2d01d2828a068eca39455f864d1e'

def generate_client_token(overrides={})
  raw_client_token = Braintree::ClientToken.generate
  client_token = JSON.parse(Base64.decode64(raw_client_token))

  if params["touchDisabled"]
    client_token["paypal"]["touchDisabled"] = true if client_token["paypalEnabled"]
  end

  client_token["paypal"]["allowHttp"] = true

  Base64.strict_encode64(JSON.dump(client_token.merge(overrides))).chomp
end

get "/client_token" do
  content_type :json
  Base64.decode64(generate_client_token)
end

get "/client_token.json" do
  content_type :json
  {:client_token => generate_client_token}.to_json
end

get "/client_token/inspect" do
  content_type :json
  JSON.pretty_generate(JSON.parse(Base64.decode64(generate_client_token)))
end

get "/config/current" do
  content_type :json
  {
    :merchant_id => Braintree::Configuration.merchant_id
  }.to_json
end

get "/dropin" do
  @client_token = generate_client_token
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
