class EnvManager
  attr_reader :envs

  def initialize(redis)
    @redis = redis
    @envs = {}
    @masked = true
  end

  def add(env)
    @envs[env.nickname] = env
  end

  def activate!(env_name=nil)
    redis_env_name = @redis.get("current_env_nickname")

    if env_name.nil? && redis_env_name.nil?
      return activate!(@envs.keys.first)
    elsif env_name.nil?
      env_name = redis_env_name
    end

    puts "Activating #{env_name}"

    @redis.set("current_env_nickname", env_name)
    @envs[env_name].activate!
  end

  def current
    {
      :environment => Braintree::Configuration.environment,
      :merchant_id => Braintree::Configuration.merchant_id,
      :public_key => _display(Braintree::Configuration.public_key),
      :private_key => _display(Braintree::Configuration.private_key)
    }
  end

  def _display(string)
    if @masked
      if string.length > 4
        string[0..3] + "*" * (string.length - 4)
      else
        "*"*string.length
      end
    else
      string
    end
  end
end
