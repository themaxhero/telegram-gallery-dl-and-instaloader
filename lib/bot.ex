defmodule TelegramGalleryDl.Bot do
  use Telegram.Bot

  require Logger

  @instagram_post_regexp ~r/\/p\/(.+)\//

  defp splitter(input) do
    line_splitter =
      case :os.type() do
        {:win32, _} -> "\r\n"
        {:unix, _} -> "\n"
      end

    String.split(input, line_splitter)
  end

  def gallery_dl(url) do
    command =
      case :os.type() do
        {:win32, _} -> "gallery-dl.exe"
        {:unix, _} -> "gallery-dl"
      end

    case System.cmd(command, [url]) do
      {output, 0} ->
        output
        |> splitter()
        |> Enum.map(fn line ->
          line
          |> String.split(" ")
          |> Enum.reverse()
          |> hd()
        end)
        |> Enum.reject(&(String.trim(&1) == ""))
        |> then(&{:ok, &1})

      {output, _} ->
        {:error, output}
    end
  end

  def instaloader(post_id) do
    case System.cmd("instaloader", ["--", "-#{post_id}"]) do
      {output, 0} ->
        output
        |> String.split(" ")
        |> Enum.reverse()
        |> Enum.drop(3)
        |> Enum.reverse()
        |> then(&{:ok, &1})

      {output, _} ->
        {:error, output}
    end
  end

  def extract_instagram_post_id(url) do
    [[_, post_id]] = Regex.scan(@instagram_post_regexp, url)
    post_id
  end

  def handle_url_type(url) do
    %{host: host, path: path} = URI.parse(url)

    case {host, Regex.match?(@instagram_post_regexp, path)} do
      {"www.instagram.com", true} ->
        path
        |> extract_instagram_post_id()
        |> instaloader()

      {"pin.it", _} ->
        gallery_dl(url)
    end
  end

  def build_send_photos_call(chat_id, message_id, file) do
    [
      chat_id: chat_id,
      reply_to_message_id: message_id,
      photo: {:file, file}
    ]
  end

  def send_photos(token, chat_id, message_id, files) do
    files
    |> Stream.reject(&(&1 in ["exists", "txt"]))
    |> Stream.map(&build_send_photos_call(chat_id, message_id, &1))
    |> Stream.map(&Telegram.Api.request(token, "sendPhoto", &1))
    |> Stream.run()

    files
    |> Enum.map(fn filepath ->
      filepath
      |> Path.expand()
      |> Path.relative_to_cwd()
    end)
    |> Enum.uniq()
    |> Enum.each(&File.rm_rf!/1)
  end

  def extract_url_from_msg(msg) do
    case msg do
      "Olha o que eu achei! " <> url ->
        url
      otherwise ->
        otherwise
    end
  end

  @impl Telegram.Bot
  def handle_update(%{"message" => %{"text" => msg, "chat" => %{"id" => chat_id, "username" => username}, "message_id" => message_id}}, token) do
    Logger.info("[#{__MODULE__}.handle_update/2] - Received Message: #{msg} | Chat ID: #{chat_id} | Message ID: #{message_id}")
    url = extract_url_from_msg(msg)
    case handle_url_type(url) do
      {:ok, files} ->
        send_photos(token, chat_id, message_id, files)

      {:error, reason} ->
        Logger.error("[#{__MODULE__}.handle_update/2] - Failed processing Message: #{msg} | Chat ID: #{chat_id} | Message ID: #{message_id} | Username: #{username}")
        Telegram.Api.request(
          token,
          "sendMessage",
          chat_id: chat_id,
          reply_to_message_id: message_id,
          text: "Não foi possível baixar a imagem do link: #{msg}\nDetalhes: #{reason}"
        )
    end
  end

  def handle_update(_update, _token) do
    :ok
  end
end
