# frozen_string_literal: true

RSpec.describe CTA::API::Client do
  # BusTracker is a concrete host class that includes CTA::API::Client.
  # Using it as the host lets us exercise the shared Client module via a real
  # endpoint (gettime) without mocking the module in isolation.
  let(:api_key) { "test_bus_key" }
  let(:client) { CTA::BusTracker.new(api_key: api_key) }
  let(:base_url) { "https://www.ctabustracker.com/bustime/api/v3" }
  let(:query_match) { hash_including(key: api_key, format: "json") }

  describe "HTTP error handling" do
    it "raises ApiError with the status code on non-2xx responses" do
      stub_request(:get, "#{base_url}/gettime")
        .with(query: query_match)
        .to_return(status: 500, body: "<html>Internal Server Error</html>")

      expect { client.time }
        .to raise_error(CTA::API::ApiError, /HTTP 500/) do |error|
          expect(error.code).to eq(500)
        end
    end

    it "wraps connection failures in CTA::API::Error" do
      stub_request(:get, "#{base_url}/gettime")
        .with(query: query_match)
        .to_raise(Faraday::ConnectionFailed.new("DNS failure"))

      expect { client.time }
        .to raise_error(CTA::API::Error, /connection failed/i)
    end

    it "wraps timeouts in CTA::API::Error" do
      stub_request(:get, "#{base_url}/gettime")
        .with(query: query_match)
        .to_raise(Faraday::TimeoutError)

      expect { client.time }
        .to raise_error(CTA::API::Error, /timed out/i)
    end

    it "wraps malformed JSON in CTA::API::Error" do
      stub_request(:get, "#{base_url}/gettime")
        .with(query: query_match)
        .to_return(status: 200, body: "not json at all",
                   headers: { "Content-Type" => "application/json" })

      expect { client.time }
        .to raise_error(CTA::API::Error, /non-JSON/)
    end
  end
end
