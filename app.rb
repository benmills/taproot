require "sinatra"
require "braintree"
require "json"
require "base64"
require "pry"
require "redis"

require "./lib/braintree_env"
require "./lib/env_manager"

class App < Sinatra::Base
  configure do
  @@redis = Redis.new(:url => "redis://#{ENV["REDIS_URL"]}")
  @@env_manager = EnvManager.new(@@redis)

  @@env_manager.add(
  BraintreeEnvironment.new(
    "Mark",
    :environment => :production,
    :merchant_id => 'nxtmb3rqt8tr35v2',
    :public_key => 'b2kqymfxnhx7wdtz',
    :private_key => '8f00a7a5df9541ec05f2fa8e1b333f29'
  ))

  @@env_manager.add(BraintreeEnvironment.new(
    "Ben",
    :environment => :production,
    :merchant_id => 'dnnsn36rs57sqvym',
    :public_key => 'pkcp77fk7m52gx3t',
    :private_key => '9a37eb11d451554bfeece5f20ec1cf35'
  ))

  @@env_manager.add(BraintreeEnvironment.new(
    "Ben Sand",
    :environment => :sandbox,
    :merchant_id => 'qh5bmbx4v6pzw93h',
    :public_key => '4fmd3mrwgc9bdvkh',
    :private_key => 'd3af2d01d2828a068eca39455f864d1e'
  ))
  @@env_manager.activate!
  end

  def control_panel_url
    url = Braintree::Configuration.instantiate.base_merchant_url
    if url =~ /sandbox/
      url.gsub("api.", "")
    else
      url.gsub("api", "www")
    end
  end

  def generate_client_token(overrides={})
    raw_client_token = Braintree::ClientToken.generate
    client_token = JSON.parse(Base64.decode64(raw_client_token))

    if params["touchDisabled"]
      client_token["paypal"]["touchDisabled"] = true if client_token["paypalEnabled"]
    end

    client_token["paypal"]["allowHttp"] = true

    Base64.strict_encode64(JSON.dump(client_token.merge(overrides))).chomp
  end

  def get_braintree_requests
    count = @@redis.llen("braintree_requests")
    count = 200 if count > 200

    (0...count).inject([]) do |result, index|
      request = JSON.parse(@@redis.lindex("braintree_requests", index))

      if request["success"]
        transaction = Braintree::Transaction.find(request["transaction_id"])
        request["transaction"] = transaction
      end

      result << request
    end
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
    @client_token = Base64.decode64(generate_client_token)
    erb :client_token
  end

  get "/" do
    @envs = @@env_manager.envs
    @current_merchant_id = @@env_manager.current[:merchant_id]
    @braintree_requests = get_braintree_requests
    @url = control_panel_url

    erb :env
  end

  post "/env" do
    @@redis.del("braintree_requests")
    @@env_manager.activate!(params[:new_env])
    redirect "/"
  end

  get "/config/current" do
    content_type :json
    JSON.pretty_generate(@@env_manager.current)
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
    braintree_request = {
      "params" => params
    }

    result = Braintree::Transaction.sale(:amount => 1, :payment_method_nonce => params["payment_method_nonce"])

    braintree_request[:success] = result.success?

    if result.success?
      braintree_request[:transaction_id] = result.transaction.id
    else
      braintree_request[:message] = result.message
    end

    @@redis.lpush("braintree_requests", braintree_request.to_json)

    redirect "/"
  end

  post "/void/:transaction_id" do
    Braintree::Transaction.void(params["transaction_id"])
    redirect "/"
  end

  post "/wipe" do
    @@redis.del("braintree_requests")
    redirect "/"
  end
end
