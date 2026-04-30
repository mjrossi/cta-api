# frozen_string_literal: true

require "faraday"
require "json"

module CTA
  module API
    module Client
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def base_uri(uri = nil)
          if uri
            @base_uri = uri
          else
            @base_uri
          end
        end
      end

      OPEN_TIMEOUT = 5
      READ_TIMEOUT = 10

      private

      def connection
        @connection ||= Faraday.new(url: self.class.base_uri) do |conn|
          conn.options.open_timeout = OPEN_TIMEOUT
          conn.options.timeout = READ_TIMEOUT
        end
      end

      def http_get(path, params = {})
        response = connection.get(path, params)
        raise CTA::API::ApiError.new(code: response.status, message: "HTTP #{response.status}") unless response.success?

        JSON.parse(response.body)
      rescue Faraday::TimeoutError
        raise CTA::API::Error, "CTA API request timed out after #{READ_TIMEOUT}s"
      rescue Faraday::ConnectionFailed => e
        raise CTA::API::Error, "CTA API connection failed: #{e.message}"
      rescue JSON::ParserError
        raise CTA::API::Error, "CTA API returned non-JSON response"
      end

      def wrap_array(object)
        if object.nil?
          []
        elsif object.is_a?(Array)
          object
        else
          [object]
        end
      end

      def wrap_results(data)
        wrap_array(data).map { |r| CTA::API::Response.new(r) }
      end
    end
  end
end
