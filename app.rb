require "rubygems"
require "sinatra"
require "rack"
require "braintree"

Braintree::Configuration.environment = :sandbox
Braintree::Configuration.merchant_id = 'qh5bmbx4v6pzw93h'
Braintree::Configuration.public_key = '4fmd3mrwgc9bdvkh'
Braintree::Configuration.private_key = 'd3af2d01d2828a068eca39455f864d1e'

class Taproot < Sinatra::Base
  get "/" do
    "OK"
  end

  get "/client_token" do
    content_type :json
    Braintree::ClientToken.generate
  end
end
