require 'spec_helper'

SingleCov.covered!

describe SplunkLogger::Client do

  let(:options) { {default_level: 'warn', token: 'test', url: 'https://localhost', max_batch_size: 2, max_queue_size: 3} }
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
      before do
        allow(@logger).to receive(:delayed?).and_return(true)
        allow(@logger).to receive(:trigger_send_log)
      end

      it "queues message" do
        @logger.info("test")
        expect(@logger.message_queue).to eq([{severity: 'info', message: 'test'}])
      end

      it "trims queue when buffer size met" do
        (1..6).each { |i| @logger.log("test#{i}") }
        expect(@logger.message_queue.map { |m| m[:message] }).to eq((2..6).map { |i| "test#{i}" })
      end

    end

    describe "synchronous" do
      it "calls send_log_now with message" do
        expect(@logger).to receive(:send_log_now).with({severity: 'info', message: 'test'}).once
        @logger.info('test')
      end
    end
  end

  describe ".trigger_send_log" do
    before do
      allow(@logger).to receive(:delayed?).and_return(true)
      allow(@logger).to receive(:send_log)
    end

    it "does not call send_log if queue size is less than batch size" do
      @logger.log("test")
      sleep 0.1
      expect(@logger).to have_received(:send_log).exactly(0).times
    end

    it "does not call send_log if queue size is equal to or greater than batch size and current_message_size is set" do
      @logger.instance_variable_set(:@current_message_size, 1)
      2.times { @logger.log("test") }
      sleep 0.1
      expect(@logger).to have_received(:send_log).exactly(0).times
    end

    it "calls send_log if queue size is equal to or greater than batch size" do
      2.times { @logger.log("test") }
      sleep 0.1
      expect(@logger).to have_received(:send_log).once
    end

    it "calls send_log if queue size is equal to or greater than batch size and cleans up thread" do
      thread_count = Thread.list.length
      2.times { @logger.log("test") }
      sleep 0.1
      expect(@logger).to have_received(:send_log).once
      expect(Thread.list.length).to eq(thread_count)
    end
  end
end
