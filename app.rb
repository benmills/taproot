require "sinatra"
require "braintree"
require "json"
require "pry"

Braintree::Configuration.environment = :sandbox
Braintree::Configuration.merchant_id = 'qh5bmbx4v6pzw93h'
Braintree::Configuration.public_key = '4fmd3mrwgc9bdvkh'
Braintree::Configuration.private_key = 'd3af2d01d2828a068eca39455f864d1e'

get "/client_token" do
  content_type :json

  {
    :client_token => Braintree::ClientToken.generate
  }.to_json
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
  result = Braintree::Transaction.sale(:amount => 1, :payment_method_nonce => params[:payment_method_nonce])

  binding.pry

  content_type :text
  result.inspect
end
