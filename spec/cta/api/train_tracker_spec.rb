# frozen_string_literal: true

RSpec.describe CTA::TrainTracker do
  let(:api_key) { "test_train_key" }
  let(:client) { described_class.new(api_key: api_key) }
  let(:base_url) { "https://lapi.transitchicago.com/api/1.0" }
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

  describe "#arrivals" do
    before do
      stub_request(:get, "#{base_url}/ttarrivals.aspx")
        .with(query: hash_including(key: api_key, outputType: "JSON"))
        .to_return(body: fixture("train_tracker/ttarrivals.json"), headers: json_headers)
    end

    it "returns an array of arrival Response objects" do
      results = client.arrivals(stpid: "30106")
      expect(results).to be_an(Array)
      expect(results.length).to eq(2)
    end

    it "returns Response objects with arrival data" do
      results = client.arrivals(stpid: "30106")
      arrival = results.first
      expect(arrival).to be_a(CTA::API::Response)
      expect(arrival["staNm"]).to eq("Southport")
      expect(arrival["rt"]).to eq("Brn")
      expect(arrival["destNm"]).to eq("Loop")
    end
  end

  describe "#positions" do
    before do
      stub_request(:get, "#{base_url}/ttpositions.aspx")
        .with(query: hash_including(key: api_key, outputType: "JSON"))
        .to_return(body: fixture("train_tracker/ttpositions.json"), headers: json_headers)
    end

    it "returns an array of route Response objects" do
      results = client.positions(rt: "brn")
      expect(results).to be_an(Array)
      expect(results.length).to eq(1)
      expect(results.first).to be_a(CTA::API::Response)
      expect(results.first["@name"]).to eq("brn")
    end

    it "accepts an array of routes" do
      stub_request(:get, "#{base_url}/ttpositions.aspx")
        .with(query: hash_including(key: api_key, outputType: "JSON", rt: "brn,red"))
        .to_return(body: fixture("train_tracker/ttpositions.json"), headers: json_headers)

      results = client.positions(rt: %w[brn red])
      expect(results).to be_an(Array)
    end
  end

  describe "#follow" do
    before do
      stub_request(:get, "#{base_url}/ttfollow.aspx")
        .with(query: hash_including(key: api_key, outputType: "JSON", runnumber: "421"))
        .to_return(body: fixture("train_tracker/ttfollow.json"), headers: json_headers)
    end

    it "returns eta Response objects for a specific train run" do
      results = client.follow(runnumber: "421")
      expect(results).to be_an(Array)
      expect(results.length).to eq(2)
      expect(results.first).to be_a(CTA::API::Response)
      expect(results.first["staNm"]).to eq("Southport")
      expect(results.first["rn"]).to eq("421")
    end
  end

  describe "empty results" do
    it "returns an empty array when no arrivals are found" do
      stub_request(:get, "#{base_url}/ttarrivals.aspx")
        .with(query: hash_including(key: api_key, outputType: "JSON"))
        .to_return(body: fixture("train_tracker/ttarrivals_empty.json"), headers: json_headers)

      results = client.arrivals(stpid: "99999")
      expect(results).to eq([])
    end
  end

  describe "error handling" do
    it "raises ApiError on API error responses" do
      stub_request(:get, "#{base_url}/ttarrivals.aspx")
        .with(query: hash_including(key: api_key, outputType: "JSON"))
        .to_return(body: fixture("train_tracker/error.json"), headers: json_headers)

      expect { client.arrivals(stpid: "30106") }
        .to raise_error(CTA::API::ApiError, /Invalid API key/)
    end
  end
end
