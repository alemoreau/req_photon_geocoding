defmodule ReqPhotonGeocoding.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/alemoreau/req_photon_geocoding"

  def project do
    [
      app: :req_photon_geocoding,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: "An Elixir client for the photon HTTP geocoding API, built on top of Req.",
      docs: [
        main: "ReqPhotonGeocoding",
        source_url: @source_url,
        source_ref: "v#{@version}"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.5.0"},
      {:plug, "~> 1.0", only: :test}
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
