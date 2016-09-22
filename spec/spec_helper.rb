require "bundler/setup"

require "single_cov"
SingleCov.setup :rspec

require "splunk_logger"

COLLECTOR_PATH = '/services/collector/event'

def prep_response(body)
  resp = OpenStruct.new
  resp.body = body
  resp
end

def mock_conn_setup(message, response_type)
  @mock_conn = double
  response = prep_response({'text' => 'Success', 'code' => 0 }) if response_type == :good
  response = prep_response({'text' => 'Bad', 'code' => 1 }) if response_type == :bad
  allow(@mock_conn).to receive(:post).with('/services/collector/event', message).and_return(response) unless response_type == :error
  allow(@mock_conn).to receive(:post).with('/services/collector/event', message).and_raise(Faraday::Error) if response_type == :error
  @logger.instance_variable_set(:@conn, @mock_conn)
end
