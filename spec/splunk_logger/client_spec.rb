require 'spec_helper'

SingleCov.covered!

describe SplunkLogger::Client do
  let(:options) { {default_level: 'info', token: 'test', url: 'https://localhost'} }

  describe 'with send_interval of 1 seconds' do
    before do
      options[:send_interval] = 1
      @logger = SplunkLogger::Client.new(options)
    end

    after { @logger.stop }

    describe 'timer tests' do
      before { allow(@logger).to receive(:send_log) }

      describe '.initialize' do
        it 'initializes' do
          expect(@logger).to be_kind_of(SplunkLogger::Client)
          expect(@logger.instance_variable_get(:@conn)).to be_kind_of(Faraday::Connection)
          expect(@logger.instance_variable_get(:@timer)).to be_kind_of(Thread)
          expect(@logger.instance_variable_get(:@send_interval)).to eq(1)
        end
      end

      describe '.start' do
        before do
          @logger.stop
          @logger.start
        end

        it 'calls send_log every 1 seconds' do
          sleep 1.01 # sleep slightly longer than 1 second since thread execution may be slightly off
          expect(@logger).to have_received(:send_log).exactly(1).times
          sleep 1.01
          expect(@logger).to have_received(:send_log).exactly(2).times
        end
      end

      describe '.stop' do
        before { @logger.stop }

        it 'stops the timer and removes the thread' do
          sleep 1.1
          expect(@logger).to have_received(:send_log).exactly(0).times
          expect(@logger.instance_variable_get(:@timer)).to eq(nil)
        end
      end

      describe 'delayed?' do
        it 'is true' do
          expect(@logger.delayed?).to eq(true)
        end
      end
    end

    describe '.send_log' do

      def self.send_log_test(count, status)
        it "sends #{count} #{count==1 ? 'entry' : 'entries'} with #{status} and#{ status == :good ? '' : ' does not' } flush messages" do
          count.times { @logger.message_queue << "#{status.to_s} test" }
          message = count.times.map { "{\"event\":\"#{status.to_s} test\"}" }.join("\n")
          mock_conn_setup(message, status)
          @logger.method(:send_log).call

          expect(@mock_conn).to have_received(:post).with(COLLECTOR_PATH, message).exactly(1).times
          expect(@logger.message_queue).to eq([]) if status == :good
          expect(@logger.message_queue).to eq(count.times.map { "#{status.to_s} test"} ) unless status == :good
        end
      end

      send_log_test(1, :good)
      send_log_test(1, :bad)
      send_log_test(1, :error)
      send_log_test(2, :good)
    end
  end



  describe 'without send_interval' do
    before do
      @logger = SplunkLogger::Client.new(options)
      allow(@logger).to receive(:send_log)
    end

    after { @logger.stop }

    describe '.initialize' do
      it 'does not create timer' do
        expect(@logger.instance_variable_get(:@timer)).to eq(nil)
      end
    end

    describe '.start' do
      before do
        @logger.stop
        @logger.start
      end

      it 'does not create timer' do
        expect(@logger.instance_variable_get(:@timer)).to eq(nil)
      end
    end

    describe '.send_log_now' do
      it 'responds true with good status' do
        message = '{"event":"good test"}'
        mock_conn_setup(message, :good)
        expect(@logger.instance_eval{ send_log_now('good test')}).to eq(true)
        expect(@mock_conn).to have_received(:post).with(COLLECTOR_PATH, message).exactly(1).times
      end

      it 'responds false with bad status' do
        message = '{"event":"bad test"}'
        mock_conn_setup(message, :bad)
        expect(@logger.instance_eval{ send_log_now('bad test')}).to eq(false)
        expect(@mock_conn).to have_received(:post).with(COLLECTOR_PATH, message).exactly(1).times
      end

      it 'sends and returns false' do
        message = '{"event":"error test"}'
        mock_conn_setup(message, :error)
        expect(@logger.instance_eval{ send_log_now('error test')}).to eq(false)
        expect(@mock_conn).to have_received(:post).with(COLLECTOR_PATH, message).exactly(1).times
      end
    end
  end
end
