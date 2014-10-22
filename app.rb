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

get "/charge/recurring" do
  @message = ""
  erb :recurring
end

get "/charge/:transaction_id" do
  @transaction = Braintree::Transaction.find(params[:transaction_id])
  @total_captured = @transaction.status_history.find_all { |t| t.status == "submitted_for_settlement" }.map { |t| t.amount.to_i }.reduce(&:+) || 0
  total_auth = @transaction.status_history.find_all { |t| t.status == "authorized" }.map { |t| t.amount.to_i }.reduce(&:+)

  search_results = Braintree::Transaction.search do |search|
      search.order_id.is @transaction.id
  end

  @total_captured += search_results.map(&:amount).map(&:to_i).reduce(&:+) || 0

  @fully_captured = @total_captured == total_auth
  @remaining_amount = total_auth - @total_captured

  erb :delayed
end

post "/charge/:transaction_id" do
  @transaction = Braintree::Transaction.find(params[:transaction_id])

  if @transaction.status == "authorized"
    result = Braintree::Transaction.submit_for_settlement(params[:transaction_id], params[:amount])

    if result.success?
      @transaction = result.transaction
    else
      @transaction = Braintree::Transaction.find(params[:transaction_id])
      puts result.message
    end

    redirect "/charge/#{@transaction.id}"
  else
    result = Braintree::Transaction.sale(
      :amount => params[:amount],
      :payment_method_token => @transaction.credit_card_details.token,
      :merchant_account_id => ENV['MERCHANT_ACCOUNT'],
      :order_id => @transaction.id,
      :options => {
        :submit_for_settlement => true
      }
    )

    if !result.success?
      puts result.message
      return "Error with partial capture"
    else
      redirect "/charge/#{@transaction.id}"
    end
  end
end

post "/charge/recurring" do
  result = Braintree::Transaction.sale(
    :amount => 10,
    :payment_method_token => params["payment-method-token"],
    :merchant_account_id => ENV['MERCHANT_ACCOUNT'],
    :recurring => true
  )

  if result.success?
    @message = "Transaction #{result.transaction.status} #{result.transaction.id}"
  else
    @message = result.message
  end

  erb :recurring
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
    :amount => 10,
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
    :amount => 10,
    :payment_method_nonce => params["payment_method_nonce"],
    :merchant_account_id => ENV['MERCHANT_ACCOUNT'],
    :options => {
      :store_in_vault => true
    }
  )

  if result.success?
    message = "Transaction #{result.transaction.status} #{result.transaction.id} payment method token #{result.transaction.credit_card_details.token}"
    transaction_id = result.transaction.id
  else
    message = result.message
    transaction_id = nil
  end

  content_type :json
  {
    :message => message,
    :transaction_id => transaction_id
  }.to_json
end

def _ensure_customer_exists(customer_id)
  begin
    Braintree::Customer.find(customer_id)
  rescue Braintree::NotFoundError
    Braintree::Customer.create(:id => customer_id)
  end
end
