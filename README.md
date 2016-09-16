## Install

Via rubygems.org:

```
$ gem install cta-api
```

## Usage

This gem allows you to access the Chicago Transit Authority API via Ruby. You can track the real-time locations of all public transportation vehicles, including buses and trains. You can obtain API keys from the CTA website:

* http://www.transitchicago.com/developers/bustracker.aspx
* http://www.transitchicago.com/developers/traintracker.aspx

While no keys are required for the CustomerAlerts API, you can find more information about this part of the API at:

* http://www.transitchicago.com/developers/alerts.aspx

## Bus Tracker

### Setup

``` ruby
require 'cta-api'

key = "XXXXXXXXXXXXXXXXXXXXXXXXX"
CTA::BusTracker.key = key
```

### Find Routes and Stops

``` ruby
# list all available routes
CTA::BusTracker.routes

# gets the available directions for the specified route (north, south, etc.)
CTA::BusTracker.directions :rt => 50

# list all stops that belong to a particular route
CTA::BusTracker.stops :rt => 50, :dir => :north
```

### Find Vehicles

``` ruby
# returns an array of vehicles that travel the given routes
CTA::BusTracker.vehicles :rt => 50

# returns an array of vehicles with the given vehicle ids
CTA::BusTracker.vehicles :vid => ["1782", "1419", "1773"]
```

### Get Predicted Arrival Times

``` ruby
# get arrival times for a list of stop ids
# note that the rt parameter is optional
CTA::BusTracker.predictions :stpid => 8923, :rt => 50

# get arrival times for a list of vehicle ids
CTA::BusTracker.predictions :vid => ["1782", "1419", "1773"]
```

### Get System Time
``` ruby
CTA::BusTracker.time
```

## Train Tracker

### Setup

``` ruby
require 'cta-api'

key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
CTA::TrainTracker.key = key
```

### Get a List of Stops and Stations

``` ruby
# stops
CTA::TrainTracker.stops

# stations
CTA::TrainTracker.stations
```

### Get Predicted Arrival Times

``` ruby
CTA::TrainTracker.arrivals :stpid => "30106"
```

## Customer Alerts

### Setup

``` ruby
require 'cta-api'
```

### Get the status of a route

``` ruby
# routes (train)
options = {
  :routeid => "red,blue"
}

CTA::CustomerAlerts.routes(options)

# routes (bus)
options = {
  :routeid => "8,36"
}

CTA::CustomerAlerts.routes(options)
```

### Get alerts from the system

```ruby
# alerts
CTA::CustomerAlerts.alerts

# alerts (with options)
options = {
  :activeonly => true,
}

CTA::CustomerAlerts.alerts(options)
```

### Get a List of routes (pre-compiled list as of 2016-09-30 - this API does not provide live route information)

``` ruby
# train_routes
CTA::CustomerAlerts.train_routes

# bus_routes
CTA::CustomerAlerts.bus_routes
```
