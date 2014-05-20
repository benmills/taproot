require "net/http"
require "open-uri"
require "json"

module TaprootCLI
  def self.url(path="")
    URI.join("http://localhost:3132", path)
  end

  def self.index
    JSON.parse(open(url).read)
  end

  def self.client_token
    JSON.parse(open(url("client_token")).read)
  end

  def self.config
    JSON.parse(open(url("config")).read)
  end

  def self.config_current
    JSON.parse(open(url("config/current")).read)
  end

  def self.config_merchant_account
    JSON.parse(open(url("config/merchant_account")).read)
  end
end
