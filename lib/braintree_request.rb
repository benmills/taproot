class BraintreeRequest
  def self.from_result(params, result)
    options = {
      "params" => params,
      "error_message" => nil
    }

    if result.success?
      options["transaction"] = {
        "id" => result.transaction.id,
        "status" => result.transaction.status,
        "payment_instrument_type" => result.transaction.payment_instrument_type,
        "control_panel_url" => _control_panel_url(result.transaction.id)
      }
    else
      options["error_message"] = result.message
      options["transaction"] = {}
    end

    new(options)
  end

  def self.from_json(json)
    new(JSON.parse(json))
  end

  def self._control_panel_url(id)
    return nil if id.nil?

    url = Braintree::Configuration.instantiate.base_merchant_url
    if url =~ /sandbox/
      url.gsub("api.", "")
    else
      url.gsub("api", "www")
    end

    "#{url}/transactions/#{id}"
  end

  attr_reader :error_message, :params, :id, :status, :payment_instrument_type, :control_panel_url

  def initialize(options)
    @params = options["params"]
    @error_message = options["error_message"]
    @id = options["transaction"]["id"]
    @status = options["transaction"]["status"]
    @payment_instrument_type = options["transaction"]["payment_instrument_type"]
    @control_panel_url = options["transaction"]["control_panel_url"]
  end

  def as_json
    {
      :params => params,
      :error_message => error_message,
      :transaction => {
        :id => id,
        :status => status,
        :payment_instrument_type => payment_instrument_type,
        :control_panel_url => control_panel_url
      }
    }
  end

  def to_json
    as_json.to_json
  end
end
