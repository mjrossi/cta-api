# frozen_string_literal: true

RSpec.describe CTA::TrainTracker do
  let(:api_key) { "test_train_key" }
  let(:client) { described_class.new(api_key: api_key) }
  let(:base_url) { "https://lapi.transitchicago.com/api/1.0" }

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
        .with(query: hash_including(key: api_key))
        .to_return(body: fixture("train_tracker/ttarrivals.xml"), headers: { "Content-Type" => "text/xml" })
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

  describe "#stops" do
    it "delegates to CTA::Shared.stops" do
      result = client.stops
      expect(result).to be_a(Hash)
      expect(result).not_to be_empty
    end
  end

  describe "#stations" do
    it "delegates to CTA::Shared.stations" do
      result = client.stations
      expect(result).to be_a(Hash)
      expect(result).not_to be_empty
    end
  end

  describe "error handling" do
    it "raises ApiError on API error responses" do
      stub_request(:get, "#{base_url}/ttarrivals.aspx")
        .with(query: hash_including(key: api_key))
        .to_return(body: fixture("train_tracker/error.xml"), headers: { "Content-Type" => "text/xml" })

      expect { client.arrivals(stpid: "30106") }
        .to raise_error(CTA::API::ApiError, /Invalid API key/)
    end
  end
end
