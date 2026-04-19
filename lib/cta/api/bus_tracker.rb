# frozen_string_literal: true

require "time"

module CTA
  class BusTracker
    include CTA::API::Client

    base_uri "https://www.ctabustracker.com/bustime/api/v3/"

    def initialize(api_key: ENV.fetch("CTA_BUS_TRACKER_API_KEY", nil))
      @api_key = api_key
      raise CTA::API::ConfigurationError, "BusTracker API key is required" unless @api_key
    end

    def time
      response = get("gettime")
      Time.parse(response["tm"])
    end

    def vehicles(vid: nil, rt: nil)
      query = build_query(vid: vid, rt: rt)
      response = get("getvehicles", query)
      wrap_results(response["vehicle"])
    end

    def routes
      response = get("getroutes")
      results = wrap_array(response["routes"])
      results.to_h { |r| [r["rt"], r["rtnm"]] }
    end

    def directions(rt:)
      response = get("getdirections", rt: rt)
      results = wrap_array(response["directions"])
      results.map { |direction| direction["id"].split[0].downcase.to_sym }
    end

    def stops(rt:, dir:)
      dir_value = dir.is_a?(Symbol) ? "#{dir} bound" : dir
      response = get("getstops", rt: rt, dir: dir_value)
      wrap_results(response["stops"])
    end

    def patterns(pid: nil, rt: nil)
      query = {}
      query[:pid] = Array(pid).join(",") if pid
      query[:rt] = rt if rt
      response = get("getpatterns", query)
      wrap_results(response["ptr"])
    end

    def predictions(stpid: nil, rt: nil, vid: nil)
      query = build_query(stpid: stpid, rt: rt, vid: vid)
      response = get("getpredictions", query)
      wrap_results(response["prd"])
    end

    def locales
      response = get("getlocalelist")
      wrap_results(response["locales"])
    end

    def detours(rt: nil, rtdir: nil)
      query = {}
      query[:rt] = Array(rt).join(",") if rt
      query[:rtdir] = rtdir if rtdir
      response = get("getdetours", query)
      wrap_results(response["dtrs"])
    end

    private

    def get(path, extra_query = {})
      response = http_get(path, { key: @api_key, format: "json" }.merge(extra_query))["bustime-response"]
      check_for_errors(response["error"])
      response
    end

    def build_query(**params)
      params.each_with_object({}) do |(key, value), query|
        query[key] = Array(value).join(",") if value
      end
    end

    def check_for_errors(error)
      return unless error

      messages = Array(error).map { |e| e["msg"] }.join("; ")
      raise CTA::API::ApiError.new(code: nil, message: messages)
    end
  end
end
