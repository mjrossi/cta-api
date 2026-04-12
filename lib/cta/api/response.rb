# frozen_string_literal: true

module CTA
  module API
    # Lightweight hash subclass that provides dot-notation access to API response fields.
    # Drop-in replacement for Hashie::Mash for read-only API data.
    class Response < Hash
      def initialize(hash = {})
        super()
        hash.each { |k, v| self[k.to_s] = v }
      end

      def method_missing(name, *args)
        key?(name.to_s) ? self[name.to_s] : super
      end

      def respond_to_missing?(name, include_private = false)
        key?(name.to_s) || super
      end
    end
  end
end
