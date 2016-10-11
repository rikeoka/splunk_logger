require 'faraday'
require 'faraday_middleware'
require 'json'

require 'splunk_logger/client/log'

module SplunkLogger
  class Client
    include SplunkLogger::Client::Log
    COLLECTOR_PATH = '/services/collector/event'

    def initialize(options = {})
      token = options[:token]
      url = options[:url]
      verify_ssl = options[:verify_ssl].nil? ? true : options[:verify_ssl]
      @default_level = options[:default_level].to_s || 'info'
      @send_interval = options[:send_interval].to_i
      @max_batch_size = (options[:max_batch_size] || 100).to_i
      @max_queue_size = (options[:max_queue_size] || 10000).to_i
      @message_queue = []
      @current_message_size = 0
      headers = {'Authorization': "Splunk #{token}", 'Content-Type': 'application/json'}
      @conn = Faraday.new(url: url, headers: headers) do |faraday|
        faraday.request :json
        faraday.response :json, content_type: 'application/json'
        faraday.adapter  Faraday.default_adapter
      end
      @conn.ssl.verify = verify_ssl
      @semaphore = Mutex.new
      start
    end

    attr_accessor :message_queue

    def start
      return unless (@timer.nil? && delayed?)
      @timer = Thread.new do
        while true do
          sleep @send_interval
          send_log
        end
      end
    end

    def stop
      return if @timer.nil?
      @timer.kill
      @timer = nil
    end

    def delayed?
      return @send_interval > 0
    end

    protected

    def send_log
      @semaphore.synchronize do
        return if @message_queue.empty? || @current_message_size > 0
      end

      until(@message_queue.empty?) do
        @semaphore.synchronize do
          @current_message_size = [@message_queue.length, @max_batch_size].min
        end
        messages = { "event": @message_queue.slice(0, @current_message_size) }
        body = messages[:event].map { |m| "#{{event: m}.to_json}" }.join("\n")

        begin
          response = @conn.post SplunkLogger::Client::COLLECTOR_PATH, body
          if response.body['text'] == 'Success' && response.body['code'] == 0
            @message_queue.shift(@current_message_size)
          else
            @current_message_size = 0
            return
          end
        rescue Faraday::Error => e
          @current_message_size = 0
          return
        end
      end

      @current_message_size = 0
    end

    def send_log_now(message)
      body = "#{{event: message}.to_json}"

      begin
        response = @conn.post SplunkLogger::Client::COLLECTOR_PATH, body
        return ( response.body['text'] == 'Success' && response.body['code'] == 0 )
      rescue Faraday::Error => e
        return false
      end
    end
  end
end
