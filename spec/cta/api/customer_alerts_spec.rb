# frozen_string_literal: true

RSpec.describe CTA::CustomerAlerts do
  let(:client) { described_class.new }
  let(:base_url) { "https://www.transitchicago.com/api/1.0" }

  describe "#routes" do
    it "returns a single train route" do
      stub_request(:get, "#{base_url}/routes.aspx")
        .with(query: { routeid: "red" })
        .to_return(body: fixture("customer_alerts/routes.xml"), headers: { "Content-Type" => "text/xml" })

      routes = client.routes(routeid: "red")
      expect(routes.count).to eq(1)
      expect(routes.first["Route"]).to eq("Red Line")
    end

    it "returns multiple train routes" do
      stub_request(:get, "#{base_url}/routes.aspx")
        .with(query: { routeid: "red,blue" })
        .to_return(body: fixture("customer_alerts/routes_multiple.xml"),
                   headers: { "Content-Type" => "text/xml" })

      routes = client.routes(routeid: "red,blue")
      expect(routes.count).to eq(2)
      route_names = routes.map { |r| r["Route"] }
      expect(route_names).to contain_exactly("Red Line", "Blue Line")
    end

    it "returns route with station id" do
      stub_request(:get, "#{base_url}/routes.aspx")
        .with(query: { stationid: "40830" })
        .to_return(body: fixture("customer_alerts/routes.xml"), headers: { "Content-Type" => "text/xml" })

      routes = client.routes(stationid: "40830")
      expect(routes.count).to eq(1)
    end

    it "returns nil when no routes match" do
      stub_request(:get, "#{base_url}/routes.aspx")
        .to_return(body: fixture("customer_alerts/routes.xml"), headers: { "Content-Type" => "text/xml" })

      routes = client.routes
      expect(routes).not_to be_nil
    end
  end

  describe "#alerts" do
    before do
      stub_request(:get, "#{base_url}/alerts.aspx")
        .to_return(body: fixture("customer_alerts/alerts.xml"), headers: { "Content-Type" => "text/xml" })
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
        .with(query: { activeonly: true })
        .to_return(body: fixture("customer_alerts/alerts.xml"), headers: { "Content-Type" => "text/xml" })

      alerts = client.alerts(activeonly: true)
      expect(alerts).not_to be_empty
    end
  end

  describe "error handling" do
    it "raises ApiError on error responses" do
      stub_request(:get, "#{base_url}/routes.aspx")
        .to_return(body: fixture("customer_alerts/error.xml"), headers: { "Content-Type" => "text/xml" })

      expect { client.routes }
        .to raise_error(CTA::API::ApiError, /Invalid parameter/)
    end
  end
end
