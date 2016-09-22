name = "splunk_logger"
require "./lib/#{name.gsub("-","/")}/version"

Gem::Specification.new name, SplunkLogger::VERSION do |s|
  s.summary = "Simple logger to send logs to your Splunk instance"
  s.authors = ["Robert Ikeoka"]
  s.email = "rikeoka@gmail.com"
  s.homepage = "https://github.com/rikeoka/#{name}"
  s.files = `git ls-files lib/ bin/ MIT-LICENSE`.split("\n")
  s.license = "MIT"

  s.required_ruby_version = '>= 2.0.0'
  s.add_runtime_dependency 'faraday', '~> 0.9', '>= 0.9'
  s.add_runtime_dependency 'faraday_middleware', '~> 0', '>= 0'
end
