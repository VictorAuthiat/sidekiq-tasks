module RedisHelper
  def clear_redis(keys_prefix = "task:*")
    Sidekiq.redis do |conn|
      conn.keys(keys_prefix).each do |key|
        conn.del(key)
      end
    end
  end
end
