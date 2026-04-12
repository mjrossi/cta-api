# frozen_string_literal: true

module CTA
  module API
    class Error < StandardError; end

    class ApiError < Error
      attr_reader :code

      def initialize(code:, message:)
        @code = code
        super("CTA API Error #{code}: #{message}")
      end
    end

    class ConfigurationError < Error; end
  end
end
