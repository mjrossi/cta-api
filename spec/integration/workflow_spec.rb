# frozen_string_literal: true

RSpec.describe "User workflows", type: :integration do
  let(:bus_key) { "test_bus_key" }
  let(:train_key) { "test_train_key" }
  let(:bus_url) { "https://www.ctabustracker.com/bustime/api/v3" }
  let(:train_url) { "https://lapi.transitchicago.com/api/1.0" }
  let(:alerts_url) { "https://www.transitchicago.com/api/1.0" }
  let(:json_headers) { { "Content-Type" => "application/json" } }

  describe "Bus route discovery: routes → directions → stops → predictions" do
    let(:client) { CTA::BusTracker.new(api_key: bus_key) }

    before do
      stub_request(:get, "#{bus_url}/getroutes")
        .with(query: hash_including(key: bus_key))
        .to_return(body: fixture("bus_tracker/getroutes.json"), headers: json_headers)
      stub_request(:get, "#{bus_url}/getdirections")
        .with(query: hash_including(key: bus_key, rt: "50"))
        .to_return(body: fixture("bus_tracker/getdirections.json"), headers: json_headers)
      stub_request(:get, "#{bus_url}/getstops")
        .with(query: hash_including(key: bus_key, rt: "50"))
        .to_return(body: fixture("bus_tracker/getstops.json"), headers: json_headers)
      stub_request(:get, "#{bus_url}/getpredictions")
        .with(query: hash_including(key: bus_key, stpid: "8923", rt: "50"))
        .to_return(body: fixture("bus_tracker/getpredictions.json"), headers: json_headers)
    end

    it "chains route discovery into arrival predictions" do
      routes = client.routes
      expect(routes).to include("50" => "Damen")

      directions = client.directions(rt: "50")
      expect(directions).to include(:northbound)

      stops = client.stops(rt: "50", dir: :northbound)
      stop = stops.find { |s| s["stpid"] == "8923" }
      expect(stop).not_to be_nil
      expect(stop["stpnm"]).to be_a(String)

      predictions = client.predictions(stpid: stop["stpid"], rt: "50")
      expect(predictions).not_to be_empty
      prediction = predictions.first
      expect(prediction["stpid"]).to eq("8923")
      expect(prediction["rt"]).to eq("50")
      expect(prediction["prdtm"]).to be_a(String)
    end
  end

  describe "Vehicle tracking: vehicles → predictions" do
    let(:client) { CTA::BusTracker.new(api_key: bus_key) }

    before do
      stub_request(:get, "#{bus_url}/getvehicles")
        .with(query: hash_including(key: bus_key, vid: "1782"))
        .to_return(body: fixture("bus_tracker/getvehicles.json"), headers: json_headers)
      stub_request(:get, "#{bus_url}/getpredictions")
        .with(query: hash_including(key: bus_key, vid: "1782"))
        .to_return(body: fixture("bus_tracker/getpredictions.json"), headers: json_headers)
    end

    it "looks up a vehicle and gets its upcoming stops" do
      vehicles = client.vehicles(vid: "1782")
      bus = vehicles.find { |v| v["vid"] == "1782" }
      expect(bus).not_to be_nil
      expect(bus["lat"]).to be_a(String)
      expect(bus["lon"]).to be_a(String)
      expect(bus["rt"]).to eq("50")

      predictions = client.predictions(vid: bus["vid"])
      expect(predictions).not_to be_empty
      expect(predictions.first["des"]).to be_a(String)
    end
  end

  describe "Train arrival + follow: arrivals → follow" do
    let(:client) { CTA::TrainTracker.new(api_key: train_key) }

    before do
      stub_request(:get, "#{train_url}/ttarrivals.aspx")
        .with(query: hash_including(key: train_key, stpid: "30106"))
        .to_return(body: fixture("train_tracker/ttarrivals.json"), headers: json_headers)
      stub_request(:get, "#{train_url}/ttfollow.aspx")
        .with(query: hash_including(key: train_key, runnumber: "421"))
        .to_return(body: fixture("train_tracker/ttfollow.json"), headers: json_headers)
    end

    it "finds an arriving train and follows its run" do
      arrivals = client.arrivals(stpid: "30106")
      expect(arrivals).not_to be_empty

      train = arrivals.first
      expect(train["staNm"]).to eq("Southport")
      expect(train["rt"]).to eq("Brn")
      run_number = train["rn"]
      expect(run_number).to eq("421")

      upcoming = client.follow(runnumber: run_number)
      expect(upcoming).not_to be_empty
      expect(upcoming.length).to be >= 2
      upcoming.each { |stop| expect(stop["rn"]).to eq("421") }
    end
  end

  describe "Service alerts: routes → alerts" do
    let(:client) { CTA::CustomerAlerts.new }

    before do
      stub_request(:get, "#{alerts_url}/routes.aspx")
        .with(query: hash_including(routeid: "red"))
        .to_return(body: fixture("customer_alerts/routes.json"), headers: json_headers)
      stub_request(:get, "#{alerts_url}/alerts.aspx")
        .with(query: hash_including(activeonly: "true"))
        .to_return(body: fixture("customer_alerts/alerts.json"), headers: json_headers)
    end

    it "checks route status then fetches active alerts" do
      routes = client.routes(routeid: "red")
      expect(routes).not_to be_empty
      route = routes.first
      expect(route["Route"]).to eq("Red Line")
      expect(route["RouteStatus"]).to be_a(String)

      alerts = client.alerts(activeonly: true)
      expect(alerts).not_to be_empty
      alert = alerts.first
      expect(alert["AlertId"]).to be_a(String)
      expect(alert["Headline"]).to be_a(String)
    end
  end

  describe "Multi-route train positions" do
    let(:client) { CTA::TrainTracker.new(api_key: train_key) }

    before do
      stub_request(:get, "#{train_url}/ttpositions.aspx")
        .with(query: hash_including(key: train_key, rt: "brn,red"))
        .to_return(body: fixture("train_tracker/ttpositions.json"), headers: json_headers)
    end

    it "gets positions for multiple routes at once" do
      positions = client.positions(rt: %w[brn red])
      expect(positions).not_to be_empty
      route = positions.first
      expect(route["@name"]).to be_a(String)
    end
  end
end
