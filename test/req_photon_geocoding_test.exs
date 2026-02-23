defmodule ReqPhotonGeocodingTest do
  use ExUnit.Case, async: true

  @berlin_search_response %{
    "features" => [
      %{
        "type" => "Feature",
        "properties" => %{
          "name" => "Berlin",
          "state" => "Berlin",
          "country" => "Germany",
          "countrycode" => "DE",
          "osm_key" => "place",
          "osm_value" => "city",
          "osm_type" => "N",
          "osm_id" => 240_109_189
        },
        "geometry" => %{
          "type" => "Point",
          "coordinates" => [13.3888599, 52.5170365]
        }
      }
    ],
    "type" => "FeatureCollection"
  }

  @reverse_response %{
    "features" => [
      %{
        "type" => "Feature",
        "properties" => %{
          "name" => "Berlin",
          "country" => "Germany",
          "countrycode" => "DE",
          "osm_key" => "place",
          "osm_value" => "city"
        },
        "geometry" => %{
          "type" => "Point",
          "coordinates" => [13.3888599, 52.5170365]
        }
      }
    ],
    "type" => "FeatureCollection"
  }

  @status_response %{"status" => "Ok", "database" => %{"import_date" => "2024-01-01"}}

  describe "search/2" do
    test "returns decoded GeoJSON on success" do
      Req.Test.stub(ReqPhotonGeocoding, fn conn ->
        assert conn.request_path == "/api"
        assert conn.query_string =~ "q=berlin"
        Req.Test.json(conn, @berlin_search_response)
      end)

      assert {:ok, body} =
               ReqPhotonGeocoding.search("berlin", plug: {Req.Test, ReqPhotonGeocoding})

      assert [feature | _] = body["features"]
      assert feature["properties"]["name"] == "Berlin"
    end

    test "forwards limit and lang parameters" do
      Req.Test.stub(ReqPhotonGeocoding, fn conn ->
        assert conn.query_string =~ "limit=1"
        assert conn.query_string =~ "lang=en"
        Req.Test.json(conn, @berlin_search_response)
      end)

      assert {:ok, _body} =
               ReqPhotonGeocoding.search("berlin",
                 plug: {Req.Test, ReqPhotonGeocoding},
                 limit: 1,
                 lang: "en"
               )
    end

    test "forwards location bias parameters" do
      Req.Test.stub(ReqPhotonGeocoding, fn conn ->
        assert conn.query_string =~ "lat=52.5"
        assert conn.query_string =~ "lon=13.4"
        assert conn.query_string =~ "zoom=12"
        Req.Test.json(conn, @berlin_search_response)
      end)

      assert {:ok, _body} =
               ReqPhotonGeocoding.search("berlin",
                 plug: {Req.Test, ReqPhotonGeocoding},
                 lat: 52.5,
                 lon: 13.4,
                 zoom: 12
               )
    end

    test "supports osm_tag parameter" do
      Req.Test.stub(ReqPhotonGeocoding, fn conn ->
        assert conn.query_string =~ "osm_tag=tourism%3Amuseum"
        Req.Test.json(conn, @berlin_search_response)
      end)

      assert {:ok, _body} =
               ReqPhotonGeocoding.search("berlin",
                 plug: {Req.Test, ReqPhotonGeocoding},
                 osm_tag: "tourism:museum"
               )
    end

    test "returns error tuple on non-200 response" do
      Req.Test.stub(ReqPhotonGeocoding, fn conn ->
        Plug.Conn.send_resp(conn, 500, "internal server error")
      end)

      assert {:error, {500, _body}} =
               ReqPhotonGeocoding.search("berlin",
                 plug: {Req.Test, ReqPhotonGeocoding},
                 retry: false
               )
    end
  end

  describe "reverse/3" do
    test "sends lat and lon and returns GeoJSON" do
      Req.Test.stub(ReqPhotonGeocoding, fn conn ->
        assert conn.request_path == "/reverse"
        assert conn.query_string =~ "lat=52.5170365"
        assert conn.query_string =~ "lon=13.3888599"
        Req.Test.json(conn, @reverse_response)
      end)

      assert {:ok, body} =
               ReqPhotonGeocoding.reverse(52.5170365, 13.3888599,
                 plug: {Req.Test, ReqPhotonGeocoding}
               )

      assert [feature | _] = body["features"]
      assert feature["properties"]["country"] == "Germany"
    end

    test "forwards radius and limit parameters" do
      Req.Test.stub(ReqPhotonGeocoding, fn conn ->
        assert conn.query_string =~ "radius=1"
        assert conn.query_string =~ "limit=5"
        Req.Test.json(conn, @reverse_response)
      end)

      assert {:ok, _body} =
               ReqPhotonGeocoding.reverse(52.5170365, 13.3888599,
                 plug: {Req.Test, ReqPhotonGeocoding},
                 radius: 1,
                 limit: 5
               )
    end
  end

  describe "structured/1" do
    test "sends structured address params and returns GeoJSON" do
      Req.Test.stub(ReqPhotonGeocoding, fn conn ->
        assert conn.request_path == "/structured"
        assert conn.query_string =~ "city=Berlin"
        assert conn.query_string =~ "countrycode=DE"
        Req.Test.json(conn, @berlin_search_response)
      end)

      assert {:ok, body} =
               ReqPhotonGeocoding.structured(
                 plug: {Req.Test, ReqPhotonGeocoding},
                 city: "Berlin",
                 countrycode: "DE"
               )

      assert [feature | _] = body["features"]
      assert feature["properties"]["country"] == "Germany"
    end
  end

  describe "status/1" do
    test "returns server status" do
      Req.Test.stub(ReqPhotonGeocoding, fn conn ->
        assert conn.request_path == "/status"
        Req.Test.json(conn, @status_response)
      end)

      assert {:ok, body} = ReqPhotonGeocoding.status(plug: {Req.Test, ReqPhotonGeocoding})
      assert body["status"] == "Ok"
    end
  end
end
