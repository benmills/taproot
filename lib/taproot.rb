require "rubygems"
require "sinatra"
require "sinatra/contrib/all"
require "braintree"
require "term/ansicolor"
require "exception_handler"
require "config_manager"
require "base64"

class Taproot < Sinatra::Base
  use ExceptionHandling
  register Sinatra::Decompile
  include Term::ANSIColor

  set :public_folder, "."
  set :views, "."
  set :static, true

  get "/web" do
    @client_token = Braintree::ClientToken.generate(params)
    erb :index
  end

  get "/" do
    content_type :json

    routes = {}
    routes["DELETE"] = Taproot.routes["DELETE"].map { |r| Taproot.decompile(r[0], r[1]) }
    routes["GET"] = Taproot.routes["GET"].map { |r| Taproot.decompile(r[0], r[1]) }
    routes["POST"] = Taproot.routes["POST"].map { |r| Taproot.decompile(r[0], r[1]) }
    routes["PUT"] = Taproot.routes["PUT"].map { |r| Taproot.decompile(r[0], r[1]) }

    JSON.pretty_generate(:message => "Taproot UP", :config => CONFIG_MANAGER.current, :routes => routes)
  end

  get "/client_token" do
    begin
      if params["customer_id"]
        Braintree::Customer.create(
          :id => params["customer_id"]
        )
      end

      decode = params.has_key?("decode")
      params.delete("decode")

      status 201
      if decode
        JSON.pretty_generate(_client_token(:decoded => true))
      else
        JSON.pretty_generate(:client_token => _client_token)
      end
    rescue Exception => e
      content_type :json
      status 422
      JSON.pretty_generate(:message => e.message)
    end
  end

  put "/customers/:customer_id" do
    result = Braintree::Customer.create(
      :id => params[:customer_id]
    )

    content_type :json

    if result.success?
      status 201
      JSON.pretty_generate(:message => "Customer #{params[:customer_id]} created")
    else
      status 422
      JSON.pretty_generate(:message => result.message)
    end
  end

  post "/nonce/customer" do
    nonce = nonce_from_params

    content_type :json
    if nonce
      JSON.pretty_generate(sale(nonce, params.fetch(:amount, 1)))
    else
      JSON.pretty_generate(
        :message => "Required params: #{server_config[:nonce_param_names].join(", or ")}"
      )
    end
  end

  post "/nonce/transaction" do
    nonce = nonce_from_params

    content_type :json
    if nonce
      JSON.pretty_generate(sale(nonce, params.fetch(:amount, 1)))
    else
      JSON.pretty_generate(
        :message => "Required params: #{server_config[:nonce_param_names].join(", or ")}"
      )
    end
  end

  post "/customers/:customer_id/vault" do
    content_type :json

    nonce = nonce_from_params
    customer_id = params[:customer_id]

    unless customer_id.present?
      status 422
      JSON.pretty_generate(:message => "Required param: customer_id")
      return
    end

    if nonce
      JSON.pretty_generate(vault(nonce, customer_id))
    else
      JSON.pretty_generate(
        :message => "Required params: #{server_config[:nonce_param_names].join(", or ")}"
      )
    end
  end

  get "/config" do
    content_type :json
    JSON.pretty_generate(CONFIG_MANAGER.as_json)
  end

  get "/config/current" do
    content_type :json
    JSON.pretty_generate(CONFIG_MANAGER.current_account.as_json)
  end

  post "/config/:name/activate" do
    content_type :json

    if CONFIG_MANAGER.has_config?(params[:name])
      status 200
      CONFIG_MANAGER.activate!(params[:name])
      JSON.pretty_generate(:message => "#{params[:name]} activated")
    else
      status 404
      JSON.pretty_generate(:message => "#{params[:name]} not found")
    end
  end

  put "/config/:name" do
    content_type :json

    if CONFIG_MANAGER.has_config?(params[:name])
      status 422
      JSON.pretty_generate(:message => "#{params[:name]} already exists")
    else
      begin
        CONFIG_MANAGER.add(
          params[:name],
          :environment => params[:environment],
          :merchant_id => params[:merchant_id],
          :public_key => params[:public_key],
          :private_key => params[:private_key]
        )
        CONFIG_MANAGER.test_environment!(params[:name])

        status 201
        JSON.pretty_generate(:message => "#{params[:name]} created")
      rescue Exception => e
        status 422
        JSON.pretty_generate(:message => e.message)
      end
    end
  end

  get "/config/merchant_account" do
    content_type :json
    JSON.pretty_generate(:merchant_account => CONFIG_MANAGER.current_merchant_account)
  end

  put "/config/merchant_account/:merchant_account" do
    content_type :json
    CONFIG_MANAGER.current_merchant_account = params[:merchant_account]
    JSON.pretty_generate(:merchant_account => CONFIG_MANAGER.current_merchant_account)
  end

  delete "/config/merchant_account" do
    content_type :json
    CONFIG_MANAGER.current_merchant_account = nil
    JSON.pretty_generate(:merchant_account => CONFIG_MANAGER.current_merchant_account)
  end

  get "/config/validate" do
    JSON.pretty_generate(:message => CONFIG_MANAGER.validate_environment!)
  end

  error do
    content_type :json
    status 400 # or whatever

    e = env['sinatra.error']
    JSON.pretty_generate({:result => 'error', :message => e.message})
  end

  not_found do
    content_type :json
    JSON.pretty_generate({:message => "Not found. GET / to see all routes"})
  end

  after do
    puts "#{bold ">>>"} #{request.env["REQUEST_METHOD"]} #{request.path} #{params.inspect}"
    puts "#{green bold "<<<"} #{_color_status(response.status.to_i)}"
    response.body.first.split("\n").each do |line|
      puts "#{green bold "<<<"} #{line}"
    end
  end

  def server_config
    {
      :nonce_param_names => ["nonce", "payment_method_nonce", "paymentMethodNonce"]
    }
  end

  def log(message)
    puts "--- [#{CONFIG_MANAGER.current}] #{message}"
  end

  def nonce_from_params
    server_config[:nonce_param_names].find do |nonce_param_name|
      if params[nonce_param_name]
        return params[nonce_param_name]
      end
    end
  end

  def sale(nonce, amount)
    transaction_params = {
      :amount => amount,
      :payment_method_nonce => nonce,
    }

    if CONFIG_MANAGER.current_merchant_account
      transaction_params[:merchant_account_id] = CONFIG_MANAGER.current_merchant_account
    end

    log("Creating transaction #{transaction_params.inspect}")

    result = Braintree::Transaction.sale(transaction_params)

    if result.transaction.present?
      void_result = Braintree::Transaction.void(result.transaction.id)
    end

    if result.success? and void_result.present? and void_result.success?
      {:message => "created #{result.transaction.id} #{result.transaction.status}"}
    else
      {:message => result.message || void_result.message}
    end

  rescue Exception => e
    {:message => e.message}
  end

  def vault(nonce, customer_id)
    log("Vaulting payment method #{nonce} for customer #{customer_id}")

    result = Braintree::PaymentMethod.create({
      :customer_id => customer_id,
      :payment_method_nonce => nonce
    })

    if result.success?
      {:message => "Vaulted payment method #{result.payment_method.token}"}
    else
      {:message => result.message}
    end
  end

  def _client_token(options = {})
    content_type :json

    raw_client_token = Braintree::ClientToken.generate(params)
    client_token = JSON.parse(Base64.decode64(raw_client_token))
    if Braintree::Configuration.environment == :production
      client_token["venmo"] = "production"
    end

    if options[:decoded]
      client_token
    else
      Base64.strict_encode64(JSON.dump(client_token))
    end
  end

  def _color_status(status)
    if status >= 400
      yellow status.to_s
    elsif status >= 500
      red status.to_s
    else
      green status.to_s
    end
  end
end
