defmodule TelegramGalleryDl.MixProject do
  use Mix.Project

  def project do
    [
      app: :telegram_gallery_dl,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {TelegramGalleryDl.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:telegram, github: "visciang/telegram", tag: "1.1.0"},
      {:hackney, "~> 1.18"}
    ]
  end
end
