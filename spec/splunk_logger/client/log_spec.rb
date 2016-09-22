require 'spec_helper'

SingleCov.covered!

describe SplunkLogger::Client do

  let(:options) { {default_level: 'warn', token: 'test', url: 'https://localhost', max_batch_size: 1, max_queue_size: 1} }
  before { @logger = SplunkLogger::Client.new(options) }
  after { @logger.stop }

  describe "logging methods" do
    def self.test_log_level(method, level)
      describe ".#{method.to_s}" do
        it "sends test message with #{method == :log ? "default" : level} level" do
          expect(@logger).to receive(:queue_or_send_message).with(level, 'test').once
          @logger.method(method).call('test')
        end
      end
    end

    test_log_level(:log, 'warn')
    test_log_level(:debug, 'debug')
    test_log_level(:info, 'info')
    test_log_level(:warn, 'warn')
    test_log_level(:error, 'error')
  end

  describe ".queue_or_send_message" do
    describe "asynchronous" do
      before { allow(@logger).to receive(:delayed?).and_return(true) }

      it "queues message" do
        @logger.info("test")
        expect(@logger.message_queue).to eq([{severity: 'info', message: 'test'}])
      end

      it "trims queue when buffer size met" do
        (1..5).each { |i| @logger.log("test#{i}") }
        expect(@logger.message_queue.map { |m| m[:message] }).to eq(['test4', 'test5'])
      end

    end

    describe "synchronous" do
      it "calls send_log_now with message" do
        expect(@logger).to receive(:send_log_now).with({severity: 'info', message: 'test'}).once
        @logger.info('test')
      end
    end
  end
end