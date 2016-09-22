require 'splunk_logger/client'

module SplunkLogger
  class << self
    # @return [SplunkLogger::Client] forwarder wrapper
    def client(options = {})
      SplunkLogger::Client.new(options)
    end
  end
end
