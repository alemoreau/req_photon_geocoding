defmodule ReqPhotonGeocoding do
  @moduledoc """
  An Elixir client for the [photon](https://github.com/komoot/photon) HTTP geocoding API,
  built on top of [Req](https://github.com/wojtekmach/req) 0.5.

  The default base URL points to the public photon demo server at `https://photon.komoot.io`.
  You can override it by passing the `:base_url` option to any function.

  ## Examples

      iex> {:ok, %{"features" => features}} = ReqPhotonGeocoding.search("berlin")
      ...> length(features) > 0
      true
  """

  @default_base_url "https://photon.komoot.io"

  # Req options that should be forwarded directly to Req.get/2 rather than
  # being serialised as query parameters.
  @req_option_keys [
    :plug,
    :adapter,
    :auth,
    :headers,
    :compress_body,
    :compressed,
    :decode_body,
    :decode_json,
    :retry,
    :max_retries,
    :cache,
    :pool_timeout,
    :receive_timeout,
    :redirect,
    :max_redirects,
    :connect_options,
    :finch,
    :finch_request,
    :unix_socket
  ]

  @doc """
  Forward geocoding – search for a place by name or address.

  ## Parameters

  - `query` – the search term (required unless using `:osm_tag` filters)
  - `opts`  – keyword list of options:
    - `:base_url`            – override the base URL (default: `#{@default_base_url}`)
    - `:limit`               – maximum number of results
    - `:lang`                – language code for results (e.g. `"en"`, `"de"`)
    - `:lat` / `:lon`        – location bias centre
    - `:zoom`                – location bias zoom (roughly corresponds to a map zoom level)
    - `:location_bias_scale` – prominence weight (0.0–1.0)
    - `:bbox`                – bounding box as `"minLon,minLat,maxLon,maxLat"`
    - `:osm_tag`             – OSM tag filter, e.g. `"tourism:museum"` (can be a list)
    - `:layer`               – layer filter, e.g. `"city"` (can be a list)
    - `:dedupe`              – set to `0` to disable deduplication
    - any other keyword is forwarded as a query parameter

  ## Examples

      iex> {:ok, result} = ReqPhotonGeocoding.search("berlin", limit: 1)
      iex> [feature | _] = result["features"]
      iex> feature["properties"]["name"]
      "Berlin"

  """
  @spec search(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def search(query, opts \\ []) do
    {base_url, req_opts, params} = split_opts(opts)
    params = Keyword.put(params, :q, query)
    get(base_url, "/api", req_opts, params)
  end

  @doc """
  Structured forward geocoding – find a place by its individual address components.

  Supported address parameters (as keyword options):
  `:countrycode`, `:state`, `:county`, `:city`, `:postcode`, `:district`,
  `:housenumber`, `:street`.

  All common parameters accepted by `search/2` are also supported.

  ## Examples

      iex> {:ok, result} = ReqPhotonGeocoding.structured(city: "Berlin", country: "Germany", limit: 1)
      iex> [feature | _] = result["features"]
      iex> feature["properties"]["country"]
      "Germany"

  """
  @spec structured(keyword()) :: {:ok, map()} | {:error, term()}
  def structured(opts \\ []) do
    {base_url, req_opts, params} = split_opts(opts)
    get(base_url, "/structured", req_opts, params)
  end

  @doc """
  Reverse geocoding – find the address at a given coordinate.

  ## Parameters

  - `lat`  – latitude (required)
  - `lon`  – longitude (required)
  - `opts` – keyword list of options:
    - `:base_url` – override the base URL
    - `:radius`   – search radius in kilometres (0–5000)
    - `:limit`    – maximum number of results
    - `:lang`     – language code for results
    - `:osm_tag`  – OSM tag filter (see `search/2`)
    - `:layer`    – layer filter (see `search/2`)

  ## Examples

      iex> {:ok, result} = ReqPhotonGeocoding.reverse(52.5170365, 13.3888599, limit: 1)
      iex> [feature | _] = result["features"]
      iex> feature["properties"]["country"]
      "Germany"

  """
  @spec reverse(number(), number(), keyword()) :: {:ok, map()} | {:error, term()}
  def reverse(lat, lon, opts \\ []) do
    {base_url, req_opts, params} = split_opts(opts)
    params = params |> Keyword.put(:lat, lat) |> Keyword.put(:lon, lon)
    get(base_url, "/reverse", req_opts, params)
  end

  @doc """
  Health check – returns the server status and the date of the loaded data.

  ## Examples

      iex> {:ok, result} = ReqPhotonGeocoding.status()
      iex> Map.has_key?(result, "status")
      true

  """
  @spec status(keyword()) :: {:ok, map()} | {:error, term()}
  def status(opts \\ []) do
    {base_url, req_opts, _params} = split_opts(opts)
    get(base_url, "/status", req_opts, [])
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp split_opts(opts) do
    {base_url, opts} = Keyword.pop(opts, :base_url, @default_base_url)
    {req_opts, params} = Keyword.split(opts, @req_option_keys)
    {base_url, req_opts, params}
  end

  defp get(base_url, path, req_opts, params) do
    url = base_url <> path
    req_opts = Keyword.put(req_opts, :params, keyword_to_params(params))

    case Req.get(url, req_opts) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Flatten list-valued query params so each value becomes its own entry,
  # which is what Req / URI expects for repeated parameters like `osm_tag`.
  defp keyword_to_params(params) do
    Enum.flat_map(params, fn
      {key, values} when is_list(values) -> Enum.map(values, &{key, &1})
      pair -> [pair]
    end)
  end
end
