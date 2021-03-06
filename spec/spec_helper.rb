ENV['RACK_ENV'] = 'test'

require 'webmock/rspec'
require 'rspec/its'
require_relative '../lib/store_search'

RSpec.configure do |config|
  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  config.before :each do
    WebMock.disable_net_connect! allow_localhost: true
  end

  config.after :each do
    WebMock.disable_net_connect! allow_localhost: true
  end
end
