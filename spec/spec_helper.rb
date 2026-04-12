# frozen_string_literal: true

require "cta-api"
require "webmock/rspec"

WebMock.disable_net_connect!

FIXTURES_PATH = File.expand_path("fixtures", __dir__)

def fixture(path)
  File.read(File.join(FIXTURES_PATH, path))
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
  config.disable_monkey_patching!
  Kernel.srand config.seed
end
