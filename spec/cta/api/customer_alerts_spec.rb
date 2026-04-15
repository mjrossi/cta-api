# frozen_string_literal: true

RSpec.describe CTA::CustomerAlerts do
  let(:client) { described_class.new }
  let(:base_url) { "https://www.transitchicago.com/api/1.0" }
  let(:json_headers) { { "Content-Type" => "application/json" } }

  describe "#routes" do
    it "returns a single train route" do
      stub_request(:get, "#{base_url}/routes.aspx")
        .with(query: hash_including(routeid: "red", outputType: "JSON"))
        .to_return(body: fixture("customer_alerts/routes.json"), headers: json_headers)

      routes = client.routes(routeid: "red")
      expect(routes.count).to eq(1)
      expect(routes.first["Route"]).to eq("Red Line")
    end

    it "returns multiple train routes" do
      stub_request(:get, "#{base_url}/routes.aspx")
        .with(query: hash_including(routeid: "red,blue", outputType: "JSON"))
        .to_return(body: fixture("customer_alerts/routes_multiple.json"), headers: json_headers)

      routes = client.routes(routeid: "red,blue")
      expect(routes.count).to eq(2)
      route_names = routes.map { |r| r["Route"] }
      expect(route_names).to contain_exactly("Red Line", "Blue Line")
    end

    it "returns route with station id" do
      stub_request(:get, "#{base_url}/routes.aspx")
        .with(query: hash_including(stationid: "40830", outputType: "JSON"))
        .to_return(body: fixture("customer_alerts/routes.json"), headers: json_headers)

      routes = client.routes(stationid: "40830")
      expect(routes.count).to eq(1)
    end

    it "returns empty array when no routes match" do
      stub_request(:get, "#{base_url}/routes.aspx")
        .with(query: hash_including(outputType: "JSON"))
        .to_return(body: fixture("customer_alerts/routes.json"), headers: json_headers)

      routes = client.routes
      expect(routes).not_to be_nil
    end
  end

  describe "#alerts" do
    before do
      stub_request(:get, "#{base_url}/alerts.aspx")
        .with(query: hash_including(outputType: "JSON"))
        .to_return(body: fixture("customer_alerts/alerts.json"), headers: json_headers)
    end

    it "returns a list of alerts" do
      alerts = client.alerts
      expect(alerts).not_to be_empty
      expect(alerts.first).to be_a(CTA::API::Response)
    end

    it "returns alerts with expected fields" do
      alerts = client.alerts
      alert = alerts.first
      expect(alert["AlertId"]).to eq("12345")
      expect(alert["Headline"]).to eq("Red Line Service Alert")
    end

    it "passes options to the API" do
      stub_request(:get, "#{base_url}/alerts.aspx")
        .with(query: hash_including(activeonly: true, outputType: "JSON"))
        .to_return(body: fixture("customer_alerts/alerts.json"), headers: json_headers)

      alerts = client.alerts(activeonly: true)
      expect(alerts).not_to be_empty
    end
  end

  describe "empty results" do
    it "returns an empty array when no routes match" do
      stub_request(:get, "#{base_url}/routes.aspx")
        .with(query: hash_including(outputType: "JSON"))
        .to_return(body: fixture("customer_alerts/routes_empty.json"), headers: json_headers)

      results = client.routes(routeid: "nonexistent")
      expect(results).to eq([])
    end

    it "returns an empty array when no alerts exist" do
      stub_request(:get, "#{base_url}/alerts.aspx")
        .with(query: hash_including(outputType: "JSON"))
        .to_return(body: fixture("customer_alerts/alerts_empty.json"), headers: json_headers)

      results = client.alerts
      expect(results).to eq([])
    end
  end

  describe "error handling" do
    it "raises ApiError on error responses" do
      stub_request(:get, "#{base_url}/routes.aspx")
        .with(query: hash_including(outputType: "JSON"))
        .to_return(body: fixture("customer_alerts/error.json"), headers: json_headers)

      expect { client.routes }
        .to raise_error(CTA::API::ApiError, /Invalid parameter/)
    end
  end
end
