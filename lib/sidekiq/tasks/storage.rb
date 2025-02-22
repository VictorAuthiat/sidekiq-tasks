module Sidekiq
  module Tasks
    class Storage
      JID_PREFIX = "task".freeze
      TIME_FORMAT = "%Y-%m-%d %H:%M:%S %z".freeze
      HISTORY_LIMIT = 10

      def self.format_time(raw_time)
        DateTime.strptime(raw_time.to_s, TIME_FORMAT).to_time.utc
      rescue Date::Error
        nil
      end

      attr_reader :task_name

      def initialize(task_name)
        @task_name = task_name
      end

      def jid_key
        "#{JID_PREFIX}:#{task_name}"
      end

      def history_key
        "#{jid_key}:history"
      end

      def last_enqueue_at
        self.class.format_time(Sidekiq.redis { |conn| conn.hget(jid_key, "last_enqueue_at") })
      end

      def history
        Sidekiq.redis { |conn| conn.lrange(history_key, 0, -1) }&.map { |raw| Sidekiq.load_json(raw) } || []
      end

      def store_last_enqueue_at(time)
        Sidekiq.redis { |conn| conn.hset(jid_key, "last_enqueue_at", time.strftime(TIME_FORMAT)) }
      end

      def store_history(jid, task_args, time)
        Sidekiq.redis do |conn|
          task_trace = {jid: jid, name: task_name, args: task_args, enqueued_at: self.class.format_time(time)}
          conn.lpush(history_key, Sidekiq.dump_json(task_trace))
          conn.ltrim(history_key, 0, HISTORY_LIMIT - 1)
        end
      end

      def store(jid, args)
        time = Time.now.utc
        store_last_enqueue_at(time)
        store_history(jid, args, time)
      end
    end
  end
end
