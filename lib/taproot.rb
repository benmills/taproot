require "rubygems"
require "sinatra"
require "braintree"

class Taproot < Sinatra::Base
  def server_config
    {
      :nonce_param_names => ["nonce", "payment_method_nonce", "paymentMethodNonce"]
    }
  end

  def nonce_from_params
    server_config[:nonce_param_names].find do |nonce_param_name|
      if params[nonce_param_name]
        return params[nonce_param_name]
      end
    end
  end

  def sale(nonce, amount)
    result = Braintree::Transaction.sale(
      :amount => amount,
      :payment_method_nonce => nonce,
    )

    if result.success?
      {:message => "created #{result.transaction.id} #{result.transaction.status}"}
    else
      {:message => result.message}
    end
  rescue Exception => e
    {:message => e.message}
  end

  get "/" do
    content_type :json
    JSON.pretty_generate(:message => "Taproot UP", :config => CONFIG_MANAGER.current)
  end

  get "/client_token" do
    content_type :json
    JSON.pretty_generate(JSON.parse(Braintree::ClientToken.generate))
  end

  post "/" do
    puts "[PARAMS] #{params.inspect}"

    nonce = nonce_from_params

    content_type :json
    if nonce
      JSON.pretty_generate(sale(nonce, params.fetch(:amount, 10)))
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
end
