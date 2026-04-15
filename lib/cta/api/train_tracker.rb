# frozen_string_literal: true

module CTA
  class TrainTracker
    include CTA::API::Client

    base_uri "https://lapi.transitchicago.com/api/1.0/"

    def initialize(api_key: ENV.fetch("CTA_TRAIN_TRACKER_API_KEY", nil))
      @api_key = api_key
      raise CTA::API::ConfigurationError, "TrainTracker API key is required" unless @api_key
    end

    def arrivals(stpid: nil, mapid: nil, max: nil)
      query = {}
      query[:stpid] = stpid if stpid
      query[:mapid] = mapid if mapid
      query[:max] = max if max

      response = get("ttarrivals.aspx", query)
      wrap_results(response["eta"])
    end

    def positions(rt:)
      route_list = Array(rt).join(",")
      response = get("ttpositions.aspx", rt: route_list)
      wrap_results(response["route"])
    end

    def follow(runnumber:)
      response = get("ttfollow.aspx", runnumber: runnumber)
      wrap_results(response["eta"])
    end

    # Deprecation layer for class-method API
    class << self
      def key=(key)
        @default_key = key
      end

      def key
        @default_key || ENV.fetch("CTA_TRAIN_TRACKER_API_KEY", nil)
      end

      %i[arrivals positions follow].each do |method_name|
        define_method(method_name) do |**opts|
          warn "[DEPRECATION] CTA::TrainTracker.#{method_name} is deprecated. " \
               "Use CTA::TrainTracker.new(api_key: '...').#{method_name} instead."
          new(api_key: key).public_send(method_name, **opts)
        end
      end
    end

    private

    def get(path, extra_query = {})
      response = http_get(path, { key: @api_key, outputType: "JSON" }.merge(extra_query))["ctatt"]
      check_for_errors(response)
      response
    end

    def check_for_errors(response)
      return if response["errCd"] == "0"

      raise CTA::API::ApiError.new(code: response["errCd"], message: response["errNm"])
    end
  end
end
