module SplunkLogger
  class Client

    # Methods to log events to Splunk
    module Log

      # Log event with default level
      #
      # Example:
      #   SplunkLogger.log("hello world")
      def log(message)
        queue_or_send_message(@default_level, message)
      end

      # Log event as debug
      #
      # Example:
      #   SplunkLogger.debug("hello world")
      def debug(message)
        queue_or_send_message('debug', message)
      end

      # Log event as info
      #
      # Example:
      #   SplunkLogger.info("hello world")
      def info(message)
        queue_or_send_message('info', message)
      end

      # Log event as warning
      #
      # Example:
      #   SplunkLogger.warn("hello world")
      def warn(message)
        queue_or_send_message('warn', message)
      end

      # Log event as error
      #
      # Example:
      #   SplunkLogger.error("hello world")
      def error(message)
        queue_or_send_message('error', message)
      end

      private
      def queue_or_send_message(level, message)
        if delayed?
          @message_queue << {severity: level, message: message}
          @message_queue.shift if @message_queue.length > @max_queue_size + @max_batch_size
          trigger_send_log if @message_queue.length >= @max_batch_size && @current_message_size == 0
          return true
        else
          send_log_now({severity: level, message: message})
        end
      end

      def trigger_send_log
        Thread.new do
          send_log
        end
      end
    end
  end
end
