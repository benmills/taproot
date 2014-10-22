require "sinatra"
require "json"
require "braintree"
require "pry"

required_env_vars = ["MERCHANT_ID", "PUBLIC_KEY", "PRIVATE_KEY", "MERCHANT_ACCOUNT", "ENVIRONMENT"]
found_env_vars = ENV.keys & required_env_vars

if found_env_vars.count != required_env_vars.count
  puts "Missing env vars: #{(required_env_vars - found_env_vars).join(", ")}"
  exit 1
end

Braintree::Configuration.environment = ENV["ENVIRONMENT"].to_sym
Braintree::Configuration.merchant_id = ENV["MERCHANT_ID"]
Braintree::Configuration.public_key = ENV["PUBLIC_KEY"]
Braintree::Configuration.private_key = ENV["PRIVATE_KEY"]
Braintree::Configuration.logger = Logger.new("/dev/null")

get "/" do
  content_type :json
  {
    :message => "OK"
  }.to_json
end

get "/client_token" do
  _ensure_customer_exists(params["customer_id"]) if params.has_key?("customer_id")

  content_type :json
  {
    :client_token => Braintree::ClientToken.generate(params)
  }.to_json
end

post "/nonce/transaction" do
  result = Braintree::Transaction.sale(
    :amount => 1,
    :payment_method_nonce => params["payment_method_nonce"],
    :merchant_account_id => ENV['MERCHANT_ACCOUNT']
  )

  if result.success?
    result = Braintree::Transaction.void(result.transaction.id)
    status_history = result.transaction.status_history.map(&:status).join("->")
    message = "Transaction #{status_history} #{result.transaction.id}"
  else
    message = result.message
  end

  content_type :json
  {
    :message => message
  }.to_json
end

post "/recurring" do
  result = Braintree::Transaction.sale(
    :amount => 1,
    :payment_method_nonce => params["payment_method_nonce"],
    :merchant_account_id => ENV['MERCHANT_ACCOUNT'],
    :options => {
      :store_in_vault => true
    }
  )

  if result.success?
    message = "Transaction #{result.transaction.status} #{result.transaction.id} payment method token #{result.transaction.credit_card_details.token}"
  else
    message = result.message
  end

  content_type :json
  {
    :message => message
  }.to_json
end

def _ensure_customer_exists(customer_id)
  begin
    Braintree::Customer.find(customer_id)
  rescue Braintree::NotFoundError
    Braintree::Customer.create(:id => customer_id)
  end
end
