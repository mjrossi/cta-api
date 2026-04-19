# frozen_string_literal: true

module CTA
  class CustomerAlerts
    include CTA::API::Client

    base_uri "https://www.transitchicago.com/api/1.0/"

    def routes(routeid: nil, stationid: nil)
      query = {}
      query[:routeid] = routeid if routeid
      query[:stationid] = stationid if stationid

      response = get("routes.aspx", "CTARoutes", query)
      wrap_results(response["RouteInfo"])
    end

    def alerts(activeonly: nil, accessibility: nil, planned: nil)
      query = {}
      query[:activeonly] = activeonly unless activeonly.nil?
      query[:accessibility] = accessibility unless accessibility.nil?
      query[:planned] = planned unless planned.nil?

      response = get("alerts.aspx", "CTAAlerts", query)
      wrap_results(response["Alert"])
    end

    private

    def get(path, envelope, extra_query = {})
      response = http_get(path, { outputType: "JSON" }.merge(extra_query))
      body = response[envelope]
      check_for_errors(body)
      body
    end

    def check_for_errors(response)
      error_code = response["ErrorCode"]
      return if error_code.nil? || error_code == "0"

      raise CTA::API::ApiError.new(code: error_code, message: response["ErrorMessage"])
    end
  end
end
