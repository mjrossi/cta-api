# Changelog

## [2.0.0] - 2026-04-12

### Breaking Changes

- **Ruby >= 3.1 required** (was 2.7)
- **API errors now raise `CTA::API::ApiError` exceptions** instead of printing to stdout with `puts`
- **Removed `Array.wrap` monkey-patch** — no longer pollutes the global `Array` class
- **Removed `hashie` dependency** — responses now use lightweight `CTA::API::Response` objects (still support both hash-style and dot-notation access)
- **HTTPS by default** for all API endpoints

### New Features

- Instance-based clients: `CTA::BusTracker.new(api_key: key)` instead of global class variables
- ENV-based configuration: `CTA_BUS_TRACKER_API_KEY`, `CTA_TRAIN_TRACKER_API_KEY`
- Custom exception hierarchy: `CTA::API::Error`, `CTA::API::ApiError`, `CTA::API::ConfigurationError`
- Proper multi-file gem structure under `lib/cta/api/`
- Full test suite with WebMock (no live API calls needed)
- RuboCop configuration for consistent code style
- GitHub Actions CI (Ruby 3.1, 3.2, 3.3)

### Deprecated

- Class-method API (`CTA::BusTracker.key = x; CTA::BusTracker.routes`) still works but emits deprecation warnings. Use instance-based API instead. Will be removed in 3.0.

## [1.0.1] - 2013-02-02

- Original release by Frank Bonetti
