if ENV.key?('RSPEC_RETRIES')
  require 'rspec/retry'

  RSpec.configure do |config|
    # show retry status in spec process
    config.verbose_retry = true
    # show exception that triggers a retry if verbose_retry is set to true
    config.display_try_failure_messages = true

    config.around :each do |example|
      example.run_with_retry retry: Integer(ENV['RSPEC_RETRIES'])
    end
  end
end
