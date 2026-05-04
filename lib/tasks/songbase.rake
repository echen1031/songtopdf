# frozen_string_literal: true

namespace :songbase do
  desc "Download https://songbase.life/api/v2/app_data into data/app_data.json (SONGBASE_APP_DATA_PATH to override)"
  task fetch: :environment do
    require "net/http"
    require "uri"

    url = Rails.application.config.songbase_app_data_url
    path = Pathname(Rails.application.config.songbase_app_data_path)

    uri = URI(url)
    raise "unsupported URL scheme #{uri.scheme}" unless uri.scheme == "https"

    body = Net::HTTP.get(uri)
    path.parent.mkpath
    File.binwrite(path, body)
    Songbase::AppDataSongQuery.reset!

    count = JSON.parse(body).fetch("songs", []).size
    puts "Wrote #{path} (#{count} songs)"
  end
end
