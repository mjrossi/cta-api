# frozen_string_literal: true

require "httparty"
require "csv"

module CTA
  class CustomerAlerts
    include HTTParty

    base_uri "https://www.transitchicago.com/api/1.0"
    format :xml

    def routes(routeid: nil, stationid: nil)
      query = {}
      query[:routeid] = routeid if routeid
      query[:stationid] = stationid if stationid

      response = self.class.get("/routes.aspx", query: query)["CTARoutes"]
      check_for_errors(response)

      results = wrap_array(response["RouteInfo"])
      results.map { |r| CTA::API::Response.new(r) } unless results.empty?
    end

    def alerts(activeonly: nil, accessibility: nil, planned: nil)
      query = {}
      query[:activeonly] = activeonly unless activeonly.nil?
      query[:accessibility] = accessibility unless accessibility.nil?
      query[:planned] = planned unless planned.nil?

      response = self.class.get("/alerts.aspx", query: query)["CTAAlerts"]
      check_for_errors(response)

      results = wrap_array(response["Alert"])
      results.map { |r| CTA::API::Response.new(r) } unless results.empty?
    end

    def stops
      CTA::Shared.stops
    end

    def stations
      CTA::Shared.stations
    end

    def self.routes_table
      rows = CSV.read(File.expand_path("data/cta_routes.csv", __dir__))
      headers = rows.first
      rows.drop(1).map { |line| headers.zip(line).to_h }
    end

    def self.train_routes
      routes_table.select { |r| r["route_type"] == "1" }
    end

    def self.bus_routes
      routes_table.select { |r| r["route_type"] == "3" }
    end

    # Deprecation layer for class-method API (routes/alerts only)
    class << self
      def routes(**opts)
        warn "[DEPRECATION] CTA::CustomerAlerts.routes class method is deprecated. " \
             "Use CTA::CustomerAlerts.new.routes instead."
        new.routes(**opts)
      end

      def alerts(**opts)
        warn "[DEPRECATION] CTA::CustomerAlerts.alerts class method is deprecated. " \
             "Use CTA::CustomerAlerts.new.alerts instead."
        new.alerts(**opts)
      end
    end

    private

    def check_for_errors(response)
      error_code = response["ErrorCode"]
      return if error_code.nil? || error_code == "0"

      raise CTA::API::ApiError.new(code: error_code, message: response["ErrorMessage"])
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
  end
end
