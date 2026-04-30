# frozen_string_literal: true

RSpec.describe CTA::BusTracker do
  let(:api_key) { "test_bus_key" }
  let(:client) { described_class.new(api_key: api_key) }
  let(:base_url) { "https://www.ctabustracker.com/bustime/api/v3" }
  let(:json_headers) { { "Content-Type" => "application/json" } }

  describe "#initialize" do
    it "accepts an api_key" do
      expect(client).to be_a(described_class)
    end

    it "raises ConfigurationError when no key is provided" do
      expect { described_class.new(api_key: nil) }
        .to raise_error(CTA::API::ConfigurationError, /API key is required/)
    end
  end

  describe "#time" do
    before do
      stub_request(:get, "#{base_url}/gettime")
        .with(query: hash_including(key: api_key, format: "json"))
        .to_return(body: fixture("bus_tracker/gettime.json"), headers: json_headers)
    end

    it "returns a Time object" do
      result = client.time
      expect(result).to be_a(Time)
    end
  end

  describe "#vehicles" do
    before do
      stub_request(:get, "#{base_url}/getvehicles")
        .with(query: hash_including(key: api_key, format: "json"))
        .to_return(body: fixture("bus_tracker/getvehicles.json"), headers: json_headers)
    end

    it "returns an array of Response objects" do
      results = client.vehicles(rt: "50")
      expect(results).to be_an(Array)
      expect(results.length).to eq(2)
      expect(results.first).to be_a(CTA::API::Response)
      expect(results.first["vid"]).to eq("1782")
    end

    it "accepts array parameters" do
      results = client.vehicles(vid: %w[1782 1419])
      expect(results).to be_an(Array)
    end
  end

  describe "#routes" do
    before do
      stub_request(:get, "#{base_url}/getroutes")
        .with(query: hash_including(key: api_key, format: "json"))
        .to_return(body: fixture("bus_tracker/getroutes.json"), headers: json_headers)
    end

    it "returns a hash of route_id => route_name" do
      result = client.routes
      expect(result).to be_a(Hash)
      expect(result["50"]).to eq("Damen")
      expect(result["8"]).to eq("Halsted")
    end
  end

  describe "#directions" do
    before do
      stub_request(:get, "#{base_url}/getdirections")
        .with(query: hash_including(key: api_key, format: "json", rt: "50"))
        .to_return(body: fixture("bus_tracker/getdirections.json"), headers: json_headers)
    end

    it "returns an array of direction symbols" do
      result = client.directions(rt: "50")
      expect(result).to contain_exactly(:northbound, :southbound)
    end
  end

  describe "#stops" do
    before do
      stub_request(:get, "#{base_url}/getstops")
        .with(query: hash_including(key: api_key, format: "json"))
        .to_return(body: fixture("bus_tracker/getstops.json"), headers: json_headers)
    end

    it "returns an array of Response objects" do
      results = client.stops(rt: "50", dir: :north)
      expect(results).to be_an(Array)
      expect(results.first["stpid"]).to eq("8923")
    end

    it "converts symbol directions to bound strings" do
      stub_request(:get, "#{base_url}/getstops")
        .with(query: hash_including(key: api_key, format: "json", rt: "50", dir: "north bound"))
        .to_return(body: fixture("bus_tracker/getstops.json"), headers: json_headers)

      client.stops(rt: "50", dir: :north)
    end
  end

  describe "#patterns" do
    before do
      stub_request(:get, "#{base_url}/getpatterns")
        .with(query: hash_including(key: api_key, format: "json", pid: "5431"))
        .to_return(body: fixture("bus_tracker/getpatterns.json"), headers: json_headers)
    end

    it "returns an array of Response objects" do
      results = client.patterns(pid: "5431")
      expect(results).to be_an(Array)
      expect(results.first["pid"]).to eq("5431")
    end
  end

  describe "#predictions" do
    before do
      stub_request(:get, "#{base_url}/getpredictions")
        .with(query: hash_including(key: api_key, format: "json"))
        .to_return(body: fixture("bus_tracker/getpredictions.json"), headers: json_headers)
    end

    it "returns an array of prediction Response objects" do
      results = client.predictions(stpid: "8923", rt: "50")
      expect(results).to be_an(Array)
      expect(results.first["stpid"]).to eq("8923")
      expect(results.first["rt"]).to eq("50")
    end
  end

  describe "#locales" do
    before do
      stub_request(:get, "#{base_url}/getlocalelist")
        .with(query: hash_including(key: api_key, format: "json"))
        .to_return(body: fixture("bus_tracker/getlocalelist.json"), headers: json_headers)
    end

    it "returns an array of locale Response objects" do
      results = client.locales
      expect(results).to be_an(Array)
      expect(results.length).to eq(2)
      expect(results.first).to be_a(CTA::API::Response)
      expect(results.first["localestring"]).to eq("en")
    end
  end

  describe "#detours" do
    before do
      stub_request(:get, "#{base_url}/getdetours")
        .with(query: hash_including(key: api_key, format: "json"))
        .to_return(body: fixture("bus_tracker/getdetours.json"), headers: json_headers)
    end

    it "returns an array of detour Response objects" do
      results = client.detours(rt: "50")
      expect(results).to be_an(Array)
      expect(results.length).to eq(2)
      expect(results.first).to be_a(CTA::API::Response)
      expect(results.first["dtrid"]).to eq("445")
    end

    it "accepts rt and rtdir parameters" do
      stub_request(:get, "#{base_url}/getdetours")
        .with(query: hash_including(key: api_key, format: "json", rt: "50", rtdir: "Northbound"))
        .to_return(body: fixture("bus_tracker/getdetours.json"), headers: json_headers)

      results = client.detours(rt: "50", rtdir: "Northbound")
      expect(results).to be_an(Array)
    end
  end

  describe "empty results" do
    it "returns an empty array when no vehicles are found" do
      stub_request(:get, "#{base_url}/getvehicles")
        .with(query: hash_including(key: api_key, format: "json"))
        .to_return(body: fixture("bus_tracker/getvehicles_empty.json"), headers: json_headers)

      results = client.vehicles(rt: "999")
      expect(results).to eq([])
    end
  end

  describe "error handling" do
    it "raises ApiError on API error responses" do
      stub_request(:get, "#{base_url}/getroutes")
        .with(query: hash_including(key: api_key, format: "json"))
        .to_return(body: fixture("bus_tracker/error.json"), headers: json_headers)

      expect { client.routes }.to raise_error(CTA::API::ApiError, /No data found/)
    end
  end
end
