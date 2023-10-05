defmodule TelegramGalleryDl.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Telegram.Poller, bots: [{TelegramGalleryDl.Bot, token: System.get_env("BOT_TOKEN"), max_bot_concurrency: 1_000}]}
    ]

    opts = [strategy: :one_for_one, name: TelegramGalleryDl.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
