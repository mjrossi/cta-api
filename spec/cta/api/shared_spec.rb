# frozen_string_literal: true

RSpec.describe CTA::Shared do
  describe ".stops" do
    it "returns a hash of stop IDs to stop names" do
      stops = described_class.stops
      expect(stops).to be_a(Hash)
      expect(stops).not_to be_empty
      stops.each do |id, name|
        expect(id).to be_a(String)
        expect(name).to be_a(String)
      end
    end
  end

  describe ".stations" do
    it "returns a hash of station names to descriptive names" do
      stations = described_class.stations
      expect(stations).to be_a(Hash)
      expect(stations).not_to be_empty
    end
  end

  describe ".stop_table" do
    it "returns an array of hashes with header keys" do
      table = described_class.stop_table
      expect(table).to be_an(Array)
      expect(table).not_to be_empty
      expect(table.first).to be_a(Hash)
      expect(table.first.keys).to include("STOP_ID", "STOP_NAME")
    end
  end
end
