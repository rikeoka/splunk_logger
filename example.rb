require 'splunk_logger'

splunk_client = SplunkLogger::Client.new(
    token: ENV['SPLUNK_TOKEN'] || 'Your Splunk Token',
    url: 'https://localhost:8088',
    verify_ssl: false,
    default_level: 'info',
    send_interval: 1,
    max_batch_size: 100,
    max_queue_size: 10000
)

(0..1000).each do |i|
  splunk_client.log("#{i} - hello world")
end

until splunk_client.message_queue.empty?
  sleep 5
end

puts 'Check your splunk instance and it should have 1000 hello world entries.'
