require "rspec"
require "rack/test"
require "pry"
require "base64"

ENV["MERCHANT_ID"] = "qh5bmbx4v6pzw93h"
ENV["PRIVATE_KEY"] = "d3af2d01d2828a068eca39455f864d1e"
ENV["PUBLIC_KEY"] = "4fmd3mrwgc9bdvkh"
ENV["MERCHANT_ACCOUNT"] = "default"
ENV["ENVIRONMENT"] = "sandbox"

require "./app"

describe "App" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe "GET /" do
    it "returns a message" do
      get "/"
      expect(last_response).to be_ok
      expect(JSON.parse(last_response.body)["message"]) == "OK"
    end
  end

  describe "GET /client_token" do
    it "returns a client token" do
      get "/client_token"
      expect(last_response).to be_ok
      expect(last_response.content_type) == "application/json"

      raw_client_token = JSON.parse(last_response.body)["client_token"]

      expect(raw_client_token.length).to be > 1
    end

    it "can include a customer" do
      customer = Braintree::Customer.create.customer

      get "/client_token?customer_id=#{customer.id}"

      expect(last_response).to be_ok
      client_token = Base64.decode64(JSON.parse(last_response.body)["client_token"])
      expect(client_token).to include("customer_id=#{customer.id}")

      Braintree::Customer.delete(customer.id)
    end

    it "will create a customer if doesn't exist" do
      new_customer_id = "testcreate#{Time.now.to_i}"

      get "/client_token?customer_id=#{new_customer_id}"

      expect(last_response).to be_ok
      client_token = Base64.decode64(JSON.parse(last_response.body)["client_token"])
      expect(client_token).to include("customer_id=#{new_customer_id}")

      Braintree::Customer.delete(new_customer_id)
    end
  end

  describe "POST /nonce/transaction" do
    it "creates a transaction" do
      post "/nonce/transaction", :payment_method_nonce => Braintree::Test::Nonce::Transactable

      expect(last_response).to be_ok
      expect(JSON.parse(last_response.body)["message"]).to include("authorized")
    end

    it "voids a transaction if it was authorized" do
      post "/nonce/transaction", :payment_method_nonce => Braintree::Test::Nonce::Transactable

      expect(last_response).to be_ok
      expect(JSON.parse(last_response.body)["message"]).to include("voided")
    end

    it "returns the error message if the transaction fails" do
      post "/nonce/transaction", :payment_method_nonce => Braintree::Test::Nonce::Consumed

      expect(last_response).to be_ok
      expect(JSON.parse(last_response.body)["message"]).to eq("Cannot use a payment_method_nonce more than once.")
    end
  end
end
