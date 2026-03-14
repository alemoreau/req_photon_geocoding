# req_photon_geocoding

An Elixir client for the [photon](https://github.com/komoot/photon) HTTP geocoding API,
built on top of [Req](https://github.com/wojtekmach/req) 0.5.

The public demo server at [photon.komoot.io](https://photon.komoot.io) is used by default.

## Installation

Add `req_photon_geocoding` to your `mix.exs`:

```elixir
def deps do
  [
    {:req_photon_geocoding, "~> 0.1.0"}
  ]
end
```

## Usage

### Forward geocoding

```elixir
{:ok, result} = ReqPhotonGeocoding.search("berlin")
result["features"]
# => [%{"properties" => %{"name" => "Berlin", "country" => "Germany", ...}, ...}]
```

### Reverse geocoding

```elixir
{:ok, result} = ReqPhotonGeocoding.reverse(52.5170365, 13.3888599)
```

### Structured search

```elixir
{:ok, result} = ReqPhotonGeocoding.structured(city: "Berlin", countrycode: "DE")
```

### Server status

```elixir
{:ok, status} = ReqPhotonGeocoding.status()
```

## Common options

All functions accept the following keyword options:

| Option                 | Description                                                             |
|------------------------|-------------------------------------------------------------------------|
| `:base_url`            | Override the base URL (default: `https://photon.komoot.io`)            |
| `:limit`               | Maximum number of results                                               |
| `:lang`                | Language code for results (e.g. `"en"`, `"de"`)                        |
| `:lat` / `:lon`        | Location bias centre                                                    |
| `:zoom`                | Location bias zoom level (default: 16)                                  |
| `:location_bias_scale` | Prominence weight 0.0–1.0 (default: 0.2)                               |
| `:bbox`                | Bounding box `"minLon,minLat,maxLon,maxLat"`                           |
| `:osm_tag`             | OSM tag filter, e.g. `"tourism:museum"` (can be a list for multiple)   |
| `:layer`               | Layer filter, e.g. `"city"` (can be a list for multiple)               |
| `:dedupe`              | Set to `0` to disable deduplication                                     |

Any option in Req's option set (e.g. `:retry`, `:receive_timeout`) can also be passed and will
be forwarded directly to `Req.get/2`.

## Testing

Req 0.5 ships with `Req.Test` for stubbing HTTP responses without hitting the network.
Add `{:plug, "~> 1.0", only: :test}` to your deps, then pass `plug: {Req.Test, MyStub}` to
any function and register a stub handler:

```elixir
Req.Test.stub(MyStub, fn conn ->
  Req.Test.json(conn, %{"features" => []})
end)

{:ok, result} = ReqPhotonGeocoding.search("berlin", plug: {Req.Test, MyStub})
```
