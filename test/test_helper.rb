# SimpleCov must start before any application code is required so that every
# loaded line is tracked. Keep this block at the very top of the file.
require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch
  add_filter "/test/"
  add_filter "/config/"
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Use FactoryBot's short syntax (create/build/...) without the FactoryBot prefix.
  include FactoryBot::Syntax::Methods

  # Add more helper methods to be used by all tests here...
  # Time-dependent behaviour is exercised via travel_to/freeze_time from
  # ActiveSupport::Testing::TimeHelpers (already mixed into this base class).
end
