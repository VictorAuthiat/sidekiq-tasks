module Sidekiq
  module Tasks
    class Storage
      JID_PREFIX = "task".freeze
      HISTORY_LIMIT = 10

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
        stored_time("last_enqueue_at")
      end

      def last_execution_at
        stored_time("last_execution_at")
      end

      def history
        redis_history = Sidekiq.redis { |conn| conn.lrange(history_key, 0, -1) }&.map do |raw|
          entry = Sidekiq.load_json(raw)
          entry["enqueued_at"] = Time.at(entry["enqueued_at"]) if entry["enqueued_at"]
          entry["executed_at"] = Time.at(entry["executed_at"]) if entry["executed_at"]
          entry
        end

        redis_history || []
      end

      def store_history(jid, task_args, time)
        Sidekiq.redis do |conn|
          task_trace = {jid: jid, name: task_name, args: task_args, enqueued_at: time.to_i}
          conn.lpush(history_key, Sidekiq.dump_json(task_trace))
          conn.ltrim(history_key, 0, HISTORY_LIMIT - 1)
        end
      end

      def store_enqueue(jid, args)
        time = Time.now
        store_time(time, "last_enqueue_at")
        store_history(jid, args, time)
      end

      def store_execution(jid)
        time = Time.now
        store_time(time, "last_execution_at")
        store_execution_time_in_history(jid, time)
      end

      private

      def store_time(time, time_key)
        Sidekiq.redis { |conn| conn.hset(jid_key, time_key, time.to_i) }
      end

      def stored_time(time_key)
        timestamp = Sidekiq.redis { |conn| conn.hget(jid_key, time_key) }

        [nil, ""].include?(timestamp) ? nil : Time.at(timestamp.to_i)
      end

      def store_execution_time_in_history(jid, time)
        Sidekiq.redis do |conn|
          conn.lrange(history_key, 0, -1).each_with_index do |raw, index|
            entry = Sidekiq.load_json(raw)
            next unless entry["jid"] == jid

            conn.lset(history_key, index, Sidekiq.dump_json(entry.merge("executed_at" => time.to_i)))
            break
          end
        end
      end
    end
  end
end
