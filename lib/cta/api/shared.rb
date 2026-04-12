# frozen_string_literal: true

require "csv"

module CTA
  class Shared
    def self.stops
      stop_table.to_h { |stop| [stop["STOP_ID"], stop["STOP_NAME"]] }
    end

    def self.stations
      stop_table.to_h { |stop| [stop["STATION_NAME"], stop["STATION_DESCRIPTIVE_NAME"]] }
    end

    def self.stop_table
      rows = CSV.read(File.expand_path("data/cta_L_stops.csv", __dir__))
      headers = rows.first
      rows.drop(1).map { |line| headers.zip(line).to_h }
    end
  end
end
