require "base64"
require "braintree"
require "json"
require "redis"
require "sinatra"
require "rest-client"

require "./lib/braintree_env"
require "./lib/braintree_request"
require "./lib/braintree_request_repository"
require "./lib/env_manager"

class App < Sinatra::Base
  configure do
    @@redis = Redis.new(:url => "redis://#{ENV["REDIS_URL"]}")
    @@braintree_request_repository = BraintreeRequestRepository.new(@@redis)
    @@env_manager = EnvManager.new(@@redis)

    @@env_manager.add(BraintreeEnvironment.new(
      "Ben Sand",
      :environment => :sandbox,
      :merchant_id => 'qh5bmbx4v6pzw93h',
      :public_key => '4fmd3mrwgc9bdvkh',
      :private_key => 'd3af2d01d2828a068eca39455f864d1e'
    ))

    @@env_manager.add(
    BraintreeEnvironment.new(
      "CC and PP Prod",
      :environment => :production,
      :merchant_id => 'dfy45jdj3dxkmz5m',
      :public_key => '8ph7456kwcnm4gdg',
      :private_key => '056b38d6ba7a5ac07dedc38c8ec7b232'
    ))

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

    @@env_manager.activate!
  end

  get "/capi_proxy/*" do
    url = request.path.split("/capi_proxy/")
  end

  get "/client_token" do
    content_type :json
    Base64.decode64(_generate_client_token)
  end

  get "/client_token.json" do
    content_type :json
    {:client_token => _generate_client_token}.to_json
  end

  get "/client_token/inspect" do
    @client_token = Base64.decode64(_generate_client_token)
    erb :client_token
  end

  get "/" do
    @envs = @@env_manager.envs
    @current_merchant_id = @@env_manager.current[:merchant_id]
    @braintree_requests = @@braintree_request_repository.get

    erb :env
  end

  get "/braintree_requests.json" do
    content_type :json
    JSON.pretty_generate(@@braintree_request_repository.get.map(&:as_json))
  end

  get "/transactions.json" do
    results = Braintree::Transaction.search do |search|
      search.created_at >= Time.now - 60*60*24*7
    end

    transactions = []

    results.each do |transaction|
      transactions << _transaction_to_json(transaction)
    end

    content_type :json
    JSON.pretty_generate({
      :transactions => transactions
    })
  end

  post "/env" do
    @@redis.del("braintree_requests")
    @@env_manager.activate!(params[:new_env])
    redirect "/"
  end

  get "/dropin" do
    @client_token = _generate_client_token
    erb :dropin
  end

  get "/custom" do
    @client_token = Braintree::ClientToken.generate
    erb :custom
  end

  post "/transaction" do
    _create_transaction(params)
    redirect "/"
  end

  post "/transaction.json" do
    content_type :json

    result = _sale(params["payment_method_nonce"])
    braintree_request = BraintreeRequest.from_result(params, result)
    @@braintree_request_repository.save(braintree_request)

    if result.success?
      _transaction_to_json(result.transaction).to_json
    else
      {
        :error => result.message
      }.to_json
    end
  end

  post "/transaction/:transaction_id/void" do
    _void_transaction(params)
    redirect "/"
  end

  post "/wipe" do
    @@redis.flushall
    redirect "/"
  end

  def _void_transaction(params)
    result = _void(params["transaction_id"])
    braintree_request = BraintreeRequest.from_result(params, result)
    @@braintree_request_repository.save(braintree_request)
    braintree_request
  end

  def _create_transaction(params)
    result = _sale(params["payment_method_nonce"])
    braintree_request = BraintreeRequest.from_result(params, result)
    @@braintree_request_repository.save(braintree_request)
    braintree_request
  end

  def _void(parse)
    Braintree::Transaction.void(params["transaction_id"])
  rescue Exception => e
    OpenStruct.new(:success? => false, :message => e.message)
  end

  def _sale(nonce)
    Braintree::Transaction.sale(:amount => 1, :payment_method_nonce => nonce)
  rescue Exception => e
    OpenStruct.new(:success? => false, :message => e.message)
  end

  def _generate_client_token(overrides={})
    raw_client_token = Braintree::ClientToken.generate
    client_token = JSON.parse(Base64.decode64(raw_client_token))

    if params["touchDisabled"]
      client_token["paypal"]["touchDisabled"] = true if client_token["paypalEnabled"]
    end

    if params["venmo"]
      client_token["venmo"] = params["venmo"]
    end

    client_token["paypal"]["allowHttp"] = true if client_token.has_key?("paypal")
    # client_token["analytics"]["url"] = "#{client_token["clientApiUrl"]}/analytics"

    Base64.strict_encode64(JSON.dump(client_token.merge(overrides))).chomp
  end

  def _transaction_to_json(transaction)
    json = {
      :id => transaction.id,
      :status => transaction.status,
      :amount => transaction.amount.to_i,
    }

    if transaction.payment_instrument_type == "credit_card"
      json[:display] = "#{transaction.credit_card_details.card_type} ending in #{transaction.credit_card_details.last_4}"
    else
      json[:display] = "PayPal #{transaction.paypal_details.payer_email}"
    end

    json
  end
end
