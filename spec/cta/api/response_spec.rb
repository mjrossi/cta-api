# frozen_string_literal: true

RSpec.describe CTA::API::Response do
  subject(:response) { described_class.new("name" => "Red Line", "status" => "Normal") }

  describe "#[]" do
    it "accesses values by string key" do
      expect(response["name"]).to eq("Red Line")
    end
  end

  describe "dot-notation access" do
    it "accesses values as methods" do
      expect(response.name).to eq("Red Line")
      expect(response.status).to eq("Normal")
    end
  end

  describe "#respond_to_missing?" do
    it "responds to existing keys" do
      expect(response.respond_to?(:name)).to be true
    end

    it "does not respond to non-existent keys" do
      expect(response.respond_to?(:nonexistent)).to be false
    end
  end

  describe "with empty hash" do
    subject(:response) { described_class.new }

    it "creates an empty response" do
      expect(response).to be_empty
    end
  end
end
