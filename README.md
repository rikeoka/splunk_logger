#Splunk Logger

About
=====
This gem can be used to send logs to Splunk directly from your Ruby App.

Install
=======

```Bash
gem install splunk_logger
```

Usage
=====

```Ruby
require 'splunk_logger'

# Setup Splunk Logging client
splunk_client = SplunkLogger::Client.new(
    token: 'Your Splunk Token',
    url: 'https://localhost:8088',
    verify_ssl: false,
    default_level: 'info',
    send_interval: 1,
    max_batch_size: 100,
    max_queue_size: 10000
)

# Send different types of logs to Splunk
# Message can be any object that can be transformed to JSON
splunk_client.log "Log entry uses default level"
splunk_client.debug "Debug entry uses debug level"
splunk_client.error "Error entry uses error level"
splunk_client.info "Info entry uses info level"
splunk_client.warn "Warn entry uses warn level"

# Methods to control asynchronous operations
splunk_client.stop # Stops the timer from sending message, does not kill client instance
splunk_client.start # Starts the timer again

# Methods to access internals
splunk_client.message_queue # Gives you direct access to the message queue
splunk_client.delayed? # Lets you know if config is asynchronous or synchronous

```

Configuration Options
=====================

* **token** (**required**) - your splunk token
* **url** (**required**) - your splunk http collector do not include url path for example https://localhost:8088/
* **verify_ssl** (**optional**) - Defaults to true, set to false for self-signed certificates
* **default_level** (**optional**) - Defaults to 'info', this gets appended to all log events under key level
* **send_interval** (**optional**) - If left blank or set to 0, all logs will be sent synchronously potentially slowing
down your application.  Interval at which the forwarder will check for messages and send to your splunk instance. 
Recommended to set a small value to minimize queue length and not slow down your application.
* **max_batch_size** (**optional**) - Defaults to 100.  This is how many messages is sent to your Splunk in one HTTP 
request.
* **max_queue_size** (**optional**) - Defaults to 10,000.  This is how many messages + max_batch_size before oldest 
messages are dropped from the queue.  Too large of a value may cause memory issues.


Contributing
============

1. Fork the repo.
2. Modify the code.
3. Write tests.
4. Submit a pull request.


Author
======
Robert Ikeoka<br/>
rikeoka@gmail.com<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/rikeoka/splunk_logger.png)](https://travis-ci.org/rikeoka/splunk_logger)
