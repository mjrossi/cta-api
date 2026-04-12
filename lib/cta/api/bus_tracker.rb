# frozen_string_literal: true

require "httparty"
require "time"

module CTA
  class BusTracker
    include HTTParty

    base_uri "https://www.ctabustracker.com/bustime/api/v1"
    format :xml

    def initialize(api_key: ENV.fetch("CTA_BUS_TRACKER_API_KEY", nil))
      @api_key = api_key
      raise CTA::API::ConfigurationError, "BusTracker API key is required" unless @api_key
    end

    def time
      response = get("/gettime")
      Time.parse(response["tm"])
    end

    def vehicles(vid: nil, rt: nil)
      query = build_query(vid: vid, rt: rt)
      response = get("/getvehicles", query)
      wrap_results(response["vehicle"])
    end

    def routes
      response = get("/getroutes")
      results = wrap_array(response["route"])
      results&.to_h { |r| [r["rt"], r["rtnm"]] }
    end

    def directions(rt:)
      response = get("/getdirections", rt: rt)
      results = wrap_array(response["dir"])
      results&.map { |direction| direction.split[0].downcase.to_sym }
    end

    def stops(rt:, dir:)
      dir_value = dir.is_a?(Symbol) ? "#{dir} bound" : dir
      response = get("/getstops", rt: rt, dir: dir_value)
      wrap_results(response["stop"])
    end

    def patterns(pid: nil, rt: nil)
      query = {}
      query[:pid] = Array(pid).join(",") if pid
      query[:rt] = rt if rt
      response = get("/getpatterns", query)
      wrap_results(response["ptr"])
    end

    def predictions(stpid: nil, rt: nil, vid: nil)
      query = build_query(stpid: stpid, rt: rt, vid: vid)
      response = get("/getpredictions", query)
      wrap_results(response["prd"])
    end

    def bulletins(rt: nil, stpid: nil)
      query = build_query(rt: rt, stpid: stpid)
      response = get("/getservicebulletins", query)
      wrap_results(response["sb"])
    end

    # Deprecation layer for class-method API
    class << self
      def key=(key)
        @default_key = key
      end

      def key
        @default_key || ENV.fetch("CTA_BUS_TRACKER_API_KEY", nil)
      end

      %i[time vehicles routes directions stops patterns predictions bulletins].each do |method_name|
        define_method(method_name) do |**opts|
          warn "[DEPRECATION] CTA::BusTracker.#{method_name} is deprecated. " \
               "Use CTA::BusTracker.new(api_key: '...').#{method_name} instead."
          new(api_key: key).public_send(method_name, **opts)
        end
      end
    end

    private

    def get(path, extra_query = {})
      response = self.class.get(path, query: { key: @api_key }.merge(extra_query))["bustime_response"]
      check_for_errors(response["error"])
      response
    end

    def build_query(**params)
      params.each_with_object({}) do |(key, value), query|
        query[key] = Array(value).join(",") if value
      end
    end

    def check_for_errors(error)
      raise CTA::API::ApiError.new(code: nil, message: error["msg"]) if error
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
