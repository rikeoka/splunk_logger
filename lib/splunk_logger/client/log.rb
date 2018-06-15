module SplunkLogger
  class Client

    # Methods to log events to Splunk
    module Log

      %w(log debug info warn error).each do |level|
        define_method level.to_s.to_sym do |log_data|
          level = (level == 'log' ? @default_level : level)
          queue_or_send_message(level, log_data)
        end
      end

      private
      def queue_or_send_message(level, log_data)
        formatted_data = log_hash(level, log_data)
        if delayed?
          @message_queue << formatted_data
          @message_queue.shift if @message_queue.length > @max_queue_size + @max_batch_size
          trigger_send_log if @message_queue.length >= @max_batch_size && @current_message_size == 0
          return true
        else
          send_log_now(formatted_data)
        end
      end

      def trigger_send_log
        return if @semaphore.locked?
        Thread.new do
          @semaphore.synchronize do
            send_log
          end
        end
      end

      def log_hash(level, log_data)
        log_data = { message: log_data } unless log_data.is_a?(Hash)
        { severity: level }.merge!(log_data)
      end
    end
  end
end
