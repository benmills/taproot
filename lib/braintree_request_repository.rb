class BraintreeRequestRepository
  CollectionKey = "braintree_requests"

  def initialize(redis)
    @redis = redis
  end

  def save(braintree_request)
    puts "[REDIS] Save #{braintree_request.to_json.inspect}"
    @redis.lpush(CollectionKey, braintree_request.to_json)
  end

  def get(limit=200)
    count = @redis.llen(CollectionKey)
    count = limit if count > limit

    (0...count).map do |index|
      json = @redis.lindex(CollectionKey, index)
      BraintreeRequest.from_json(json)
    end
  end
end
