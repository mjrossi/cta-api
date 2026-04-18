# frozen_string_literal: true

module CTA
  module API
    # Shallow, read-only analogue to Hashie::Mash. Dot-notation works at the top
    # level only; fields whose names collide with Hash methods (size, keys, count,
    # etc.) must be accessed via [].
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
