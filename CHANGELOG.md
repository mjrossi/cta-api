# Changelog

## [2.0.0] - 2026-04-18

### Breaking Changes

- **Ruby >= 3.1 required** (was 2.7)
- **API errors now raise `CTA::API::ApiError` exceptions** instead of printing to stdout with `puts`
- **Removed `Array.wrap` monkey-patch** — no longer pollutes the global `Array` class
- **Removed `hashie` dependency** — responses now use lightweight `CTA::API::Response` objects (still support both hash-style and dot-notation access)
- **HTTPS by default** for all API endpoints
- **Removed bundled CSV data** (`cta_L_stops.csv`, `cta_routes.csv`) and the methods that read them: `CTA::TrainTracker#stops`, `CTA::TrainTracker#stations`, `CTA::CustomerAlerts#stops`, `CTA::CustomerAlerts.train_routes`, `CTA::CustomerAlerts.bus_routes`. This data drifts out of date; use the [CTA GTFS feed](https://www.transitchicago.com/developers/gtfs/) for static stop/station/route information.
- **Bus Tracker API upgraded from v1 to v3** — new base URL, structured direction responses, JSON responses. JSON response keys differ from the old XML shape for `routes`, `directions`, `stops`, and `detours` endpoints (e.g., `"route"` → `"routes"`, `"dir"` → `"directions"`). v3 directions return structured objects with `id`/`name` fields, but the `directions` method still returns symbols (`:northbound`, etc.), so the public API is unchanged.
- **All APIs now use JSON responses** — XML parsing removed entirely
- **Replaced HTTParty with Faraday** — single runtime dependency; JSON parsed via stdlib
- **Empty results return `[]`** instead of `nil`
- **Removed class-method API** — `CTA::BusTracker.key=`, `CTA::BusTracker.routes`, and equivalent class methods on `TrainTracker` and `CustomerAlerts` are gone. Use instance-based clients.
- **Removed `CTA::BusTracker#bulletins`** — use `CTA::BusTracker#detours` instead. The `getservicebulletins` endpoint is not documented in Bus Tracker API v3.

### New Features

- Instance-based clients: `CTA::BusTracker.new(api_key: key)` instead of global class variables
- ENV-based configuration: `CTA_BUS_TRACKER_API_KEY`, `CTA_TRAIN_TRACKER_API_KEY`
- Custom exception hierarchy: `CTA::API::Error`, `CTA::API::ApiError`, `CTA::API::ConfigurationError`
- Proper multi-file gem structure under `lib/cta/api/`
- Full test suite with WebMock (no live API calls needed)
- RuboCop configuration for consistent code style
- GitHub Actions CI (Ruby 3.1, 3.2, 3.3, 3.4)
- **New Bus Tracker endpoints**: `locales` (supported locales), `detours` (active detours by route)
- **New Train Tracker endpoints**: `positions` (train locations by route), `follow` (follow a specific train run)
- Extracted shared `CTA::API::Client` module — eliminates code duplication across client classes
- HTTP timeouts (5s open, 10s read) and wrapped error handling — network, timeout, and JSON-parse failures raise `CTA::API::Error` instead of leaking `Faraday::*` or `JSON::ParserError`. HTTP non-2xx responses raise `CTA::API::ApiError` with the status code.

## [1.0.1] - 2013-02-02

- Original release by Frank Bonetti
