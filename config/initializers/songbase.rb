# frozen_string_literal: true

Rails.application.config.songbase_app_data_path =
  ENV["SONGBASE_APP_DATA_PATH"].presence ||
  if Rails.env.test?
    Rails.root.join("test/fixtures/files/minimal_app_data.json").to_s
  else
    Rails.root.join("data", "app_data.json").to_s
  end

Rails.application.config.songbase_app_data_url =
  ENV.fetch("SONGBASE_APP_DATA_URL", "https://songbase.life/api/v2/app_data")
