# frozen_string_literal: true

RSpec.describe "Deprecation layer" do
  let(:bus_key) { "test_bus_key" }
  let(:train_key) { "test_train_key" }
  let(:bus_base_url) { "https://www.ctabustracker.com/bustime/api/v3" }
  let(:train_base_url) { "https://lapi.transitchicago.com/api/1.0" }
  let(:alerts_base_url) { "https://www.transitchicago.com/api/1.0" }
  let(:json_headers) { { "Content-Type" => "application/json" } }

  describe "CTA::BusTracker class methods" do
    before do
      CTA::BusTracker.key = bus_key
      stub_request(:get, "#{bus_base_url}/getroutes")
        .with(query: hash_including(key: bus_key, format: "json"))
        .to_return(body: fixture("bus_tracker/getroutes.json"), headers: json_headers)
    end

    it "emits a deprecation warning" do
      expect { CTA::BusTracker.routes }.to output(/DEPRECATION/).to_stderr
    end

    it "delegates to an instance" do
      result = suppress_warnings { CTA::BusTracker.routes }
      expect(result).to be_a(Hash)
    end
  end

  describe "CTA::BusTracker.key= / .key" do
    it "stores and retrieves the default key" do
      CTA::BusTracker.key = "my_key"
      expect(CTA::BusTracker.key).to eq("my_key")
    end

    it "falls back to ENV['CTA_BUS_TRACKER_API_KEY'] when no key is set" do
      CTA::BusTracker.key = nil
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("CTA_BUS_TRACKER_API_KEY", nil).and_return("env_bus_key")
      expect(CTA::BusTracker.key).to eq("env_bus_key")
    end
  end

  describe "CTA::TrainTracker.key= / .key" do
    it "falls back to ENV['CTA_TRAIN_TRACKER_API_KEY'] when no key is set" do
      CTA::TrainTracker.key = nil
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("CTA_TRAIN_TRACKER_API_KEY", nil).and_return("env_train_key")
      expect(CTA::TrainTracker.key).to eq("env_train_key")
    end
  end

  describe "CTA::TrainTracker class methods" do
    before do
      CTA::TrainTracker.key = train_key
      stub_request(:get, "#{train_base_url}/ttarrivals.aspx")
        .with(query: hash_including(key: train_key, outputType: "JSON"))
        .to_return(body: fixture("train_tracker/ttarrivals.json"), headers: json_headers)
    end

    it "emits a deprecation warning" do
      expect { CTA::TrainTracker.arrivals(stpid: "30106") }.to output(/DEPRECATION/).to_stderr
    end

    it "delegates to an instance" do
      result = suppress_warnings { CTA::TrainTracker.arrivals(stpid: "30106") }
      expect(result).to be_an(Array)
    end
  end

  describe "CTA::CustomerAlerts class methods" do
    before do
      stub_request(:get, "#{alerts_base_url}/routes.aspx")
        .with(query: hash_including(outputType: "JSON"))
        .to_return(body: fixture("customer_alerts/routes.json"), headers: json_headers)
    end

    it "emits a deprecation warning" do
      expect { CTA::CustomerAlerts.routes }.to output(/DEPRECATION/).to_stderr
    end

    it "delegates to an instance" do
      result = suppress_warnings { CTA::CustomerAlerts.routes }
      expect(result).to be_an(Array)
    end
  end

  describe "CTA::BusTracker#bulletins deprecation" do
    let(:client) { CTA::BusTracker.new(api_key: bus_key) }

    before do
      stub_request(:get, "#{bus_base_url}/getservicebulletins")
        .with(query: hash_including(key: bus_key, format: "json"))
        .to_return(body: fixture("bus_tracker/getservicebulletins.json"), headers: json_headers)
    end

    it "emits a deprecation warning pointing to detours" do
      expect { client.bulletins(rt: "50") }.to output(/DEPRECATION.*detours/).to_stderr
    end
  end

  private

  def suppress_warnings
    original_stderr = $stderr
    $stderr = StringIO.new
    yield
  ensure
    $stderr = original_stderr
  end
end
