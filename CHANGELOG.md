# Splunk logging for Ruby

## Version 0.0.3
* Fixed a bug that was causing the default level to not be set to info if no paramater is provided when creating the 
client

## Version 0.0.2
* Add trigger to send logs when max_batch_size is met
* Added thread protection to prevent multiple threads from sending simultaneously

## Version 0.0.1
* Remove faraday logger output
* Allow example.rb token to come from env variable.

## Version 0.0.0
* Initial release