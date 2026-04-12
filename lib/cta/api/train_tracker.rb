# frozen_string_literal: true

require "httparty"

module CTA
  class TrainTracker
    include HTTParty

    base_uri "https://lapi.transitchicago.com/api/1.0"
    format :xml

    def initialize(api_key: ENV.fetch("CTA_TRAIN_TRACKER_API_KEY", nil))
      @api_key = api_key
      raise CTA::API::ConfigurationError, "TrainTracker API key is required" unless @api_key
    end

    def arrivals(stpid: nil, mapid: nil, max: nil)
      query = {}
      query[:stpid] = stpid if stpid
      query[:mapid] = mapid if mapid
      query[:max] = max if max

      response = get("/ttarrivals.aspx", query)
      wrap_results(response["eta"])
    end

    def stops
      CTA::Shared.stops
    end

    def stations
      CTA::Shared.stations
    end

    # Deprecation layer for class-method API
    class << self
      def key=(key)
        @default_key = key
      end

      def key
        @default_key || ENV.fetch("CTA_TRAIN_TRACKER_API_KEY", nil)
      end

      def arrivals(**opts)
        warn "[DEPRECATION] CTA::TrainTracker.arrivals is deprecated. " \
             "Use CTA::TrainTracker.new(api_key: '...').arrivals instead."
        new(api_key: key).arrivals(**opts)
      end
    end

    private

    def get(path, extra_query = {})
      response = self.class.get(path, query: { key: @api_key }.merge(extra_query))["ctatt"]
      check_for_errors(response)
      response
    end

    def check_for_errors(response)
      return if response["errCd"] == "0"

      raise CTA::API::ApiError.new(code: response["errCd"], message: response["errNm"])
    end

    def wrap_array(object)
      if object.nil?
        []
      elsif object.respond_to?(:to_ary)
        object.to_ary || [object]
      else
        [object]
      end
    end

    def wrap_results(data)
      results = wrap_array(data)
      results.map { |r| CTA::API::Response.new(r) } unless results.empty?
    end
  end
end
