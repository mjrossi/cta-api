# CTA API

[![CI](https://github.com/mjrossi/cta-api/actions/workflows/ci.yml/badge.svg)](https://github.com/mjrossi/cta-api/actions/workflows/ci.yml)

A Ruby gem for accessing the Chicago Transit Authority (CTA) API. Track real-time bus and train locations, get arrival predictions, and check service alerts.

## Installation

Add to your Gemfile:

```ruby
gem "cta-api"
```

Or install directly:

```
gem install cta-api
```

## Configuration

API keys are required for Bus Tracker and Train Tracker. Get yours at:

- **Bus Tracker**: https://www.transitchicago.com/developers/bustracker.aspx
- **Train Tracker**: https://www.transitchicago.com/developers/traintracker.aspx
- **Customer Alerts**: No key required

You can pass keys directly or set environment variables:

```bash
export CTA_BUS_TRACKER_API_KEY="your_bus_key"
export CTA_TRAIN_TRACKER_API_KEY="your_train_key"
```

## Usage

### Bus Tracker

```ruby
require "cta-api"

client = CTA::BusTracker.new(api_key: "your_key")
# Or, if ENV["CTA_BUS_TRACKER_API_KEY"] is set:
client = CTA::BusTracker.new

# List all routes
client.routes
# => {"50"=>"Damen", "8"=>"Halsted", ...}

# Get directions for a route
client.directions(rt: "50")
# => [:northbound, :southbound]

# List stops for a route and direction
client.stops(rt: "50", dir: :north)

# Get real-time vehicle locations
client.vehicles(rt: "50")
client.vehicles(vid: ["1782", "1419"])

# Get arrival predictions
client.predictions(stpid: "8923", rt: "50")
client.predictions(vid: ["1782", "1419"])

# Get service bulletins
client.bulletins(rt: "50")

# Get system time
client.time
```

### Train Tracker

```ruby
client = CTA::TrainTracker.new(api_key: "your_key")

# Get arrival predictions
client.arrivals(stpid: "30106")
```

### Customer Alerts

```ruby
client = CTA::CustomerAlerts.new  # No API key needed

# Get route status
client.routes(routeid: "red")
client.routes(routeid: "red,blue")
client.routes(stationid: "40830")

# Get service alerts
client.alerts
client.alerts(activeonly: true)
```

### Error Handling

```ruby
begin
  client.routes
rescue CTA::API::ConfigurationError => e
  # Missing API key
rescue CTA::API::ApiError => e
  # CTA API returned an error
  puts e.message  # => "CTA API Error 500: Invalid parameter"
  puts e.code     # => "500"
end
```

## Migrating from 1.x to 2.0

### Breaking Changes

- **Ruby >= 3.1 required** (was 2.7)
- **API errors raise exceptions** instead of printing to stdout
- **HTTPS by default** for all endpoints
- **`Array.wrap` monkey-patch removed**
- **`hashie` dependency removed** — responses use `CTA::API::Response` (same hash/dot-notation access)
- **Bundled CSV data removed** — `CTA::TrainTracker#stops`, `#stations`, `CTA::CustomerAlerts.train_routes`, and `CTA::CustomerAlerts.bus_routes` are gone. For static stop/station/route data, use the CTA's [GTFS feed](https://www.transitchicago.com/developers/gtfs/) directly.

### Deprecated (will be removed in 3.0)

The old class-method API still works but emits deprecation warnings:

```ruby
# Old (deprecated):
CTA::BusTracker.key = "your_key"
CTA::BusTracker.routes

# New:
client = CTA::BusTracker.new(api_key: "your_key")
client.routes
```

## Development

```bash
git clone https://github.com/mjrossi/cta-api.git
cd cta-api
bundle install
bundle exec rake        # runs rubocop + rspec
bundle exec rspec       # tests only
bundle exec rubocop     # lint only
```

## License

MIT License. See [LICENSE](LICENSE) for details.
