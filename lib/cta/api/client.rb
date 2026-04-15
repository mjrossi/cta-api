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

      private

      def connection
        @connection ||= Faraday.new(url: self.class.base_uri)
      end

      def http_get(path, params = {})
        response = connection.get(path, params)
        JSON.parse(response.body)
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
