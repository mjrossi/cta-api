# frozen_string_literal: true

RSpec.describe CTA::BusTracker do
  let(:api_key) { "test_bus_key" }
  let(:client) { described_class.new(api_key: api_key) }
  let(:base_url) { "https://www.ctabustracker.com/bustime/api/v1" }

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
        .with(query: { key: api_key })
        .to_return(body: fixture("bus_tracker/gettime.xml"), headers: { "Content-Type" => "text/xml" })
    end

    it "returns a Time object" do
      result = client.time
      expect(result).to be_a(Time)
    end
  end

  describe "#vehicles" do
    before do
      stub_request(:get, "#{base_url}/getvehicles")
        .with(query: hash_including(key: api_key))
        .to_return(body: fixture("bus_tracker/getvehicles.xml"), headers: { "Content-Type" => "text/xml" })
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
        .with(query: { key: api_key })
        .to_return(body: fixture("bus_tracker/getroutes.xml"), headers: { "Content-Type" => "text/xml" })
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
        .with(query: hash_including(key: api_key, rt: "50"))
        .to_return(body: fixture("bus_tracker/getdirections.xml"), headers: { "Content-Type" => "text/xml" })
    end

    it "returns an array of direction symbols" do
      result = client.directions(rt: "50")
      expect(result).to contain_exactly(:northbound, :southbound)
    end
  end

  describe "#stops" do
    before do
      stub_request(:get, "#{base_url}/getstops")
        .with(query: hash_including(key: api_key, rt: "50"))
        .to_return(body: fixture("bus_tracker/getstops.xml"), headers: { "Content-Type" => "text/xml" })
    end

    it "returns an array of Response objects" do
      results = client.stops(rt: "50", dir: :north)
      expect(results).to be_an(Array)
      expect(results.first["stpid"]).to eq("8923")
    end

    it "converts symbol directions to bound strings" do
      stub_request(:get, "#{base_url}/getstops")
        .with(query: { key: api_key, rt: "50", dir: "north bound" })
        .to_return(body: fixture("bus_tracker/getstops.xml"), headers: { "Content-Type" => "text/xml" })

      client.stops(rt: "50", dir: :north)
    end
  end

  describe "#patterns" do
    before do
      stub_request(:get, "#{base_url}/getpatterns")
        .with(query: hash_including(key: api_key))
        .to_return(body: fixture("bus_tracker/getpatterns.xml"), headers: { "Content-Type" => "text/xml" })
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
        .with(query: hash_including(key: api_key))
        .to_return(body: fixture("bus_tracker/getpredictions.xml"), headers: { "Content-Type" => "text/xml" })
    end

    it "returns an array of prediction Response objects" do
      results = client.predictions(stpid: "8923", rt: "50")
      expect(results).to be_an(Array)
      expect(results.first["stpid"]).to eq("8923")
      expect(results.first["rt"]).to eq("50")
    end
  end

  describe "#bulletins" do
    before do
      stub_request(:get, "#{base_url}/getservicebulletins")
        .with(query: hash_including(key: api_key))
        .to_return(body: fixture("bus_tracker/getservicebulletins.xml"), headers: { "Content-Type" => "text/xml" })
    end

    it "returns an array of bulletin Response objects" do
      results = client.bulletins(rt: "50")
      expect(results).to be_an(Array)
      expect(results.first["nm"]).to eq("Reroute Alert")
    end
  end

  describe "error handling" do
    it "raises ApiError on API error responses" do
      stub_request(:get, "#{base_url}/getroutes")
        .with(query: { key: api_key })
        .to_return(body: fixture("bus_tracker/error.xml"), headers: { "Content-Type" => "text/xml" })

      expect { client.routes }.to raise_error(CTA::API::ApiError, /No data found/)
    end
  end
end
