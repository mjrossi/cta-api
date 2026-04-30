# frozen_string_literal: true

require_relative "lib/cta/api/version"

Gem::Specification.new do |s|
  s.name = "cta-api"
  s.version = CTA::API::VERSION
  s.authors = ["Frank Bonetti", "mjrossi"]
  s.email = ["mjrossi@users.noreply.github.com"]

  s.summary = "Ruby wrapper for the Chicago Transit Authority API"
  s.description = "Access the Chicago Transit Authority API for real-time bus and train tracking, " \
                  "arrival predictions, and service alerts."
  s.homepage = "https://github.com/mjrossi/cta-api"
  s.license = "MIT"

  s.required_ruby_version = ">= 3.1"
  s.platform = Gem::Platform::RUBY

  s.metadata = {
    "source_code_uri" => "https://github.com/mjrossi/cta-api",
    "changelog_uri" => "https://github.com/mjrossi/cta-api/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "https://github.com/mjrossi/cta-api/issues",
    "rubygems_mfa_required" => "true"
  }

  s.require_paths = ["lib"]
  s.files = Dir["lib/**/*", "LICENSE", "README.md"]

  s.add_dependency "faraday", "~> 2.0"
end
