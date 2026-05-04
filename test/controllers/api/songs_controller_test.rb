# frozen_string_literal: true

require "test_helper"

module Api
  class SongsControllerTest < ActionDispatch::IntegrationTest
    setup { Songbase::AppDataSongQuery.reset! }

    test "show returns song json" do
      get api_song_path(303)
      assert_response :success
      body = JSON.parse(response.body)
      assert_equal "Father Abraham", body["title"]
    end

    test "show is not found for missing id" do
      get api_song_path(999_999)
      assert_response :not_found
    end

    test "lookup returns songs wrapper" do
      post lookup_api_songs_path, params: { ids: [304, 303] }, as: :json
      assert_response :success
      body = JSON.parse(response.body)
      assert_equal [304, 303], body["songs"].map { |s| s["id"] }
    end

    test "lookup rejects non-array ids" do
      post lookup_api_songs_path, params: { ids: "303" }, as: :json
      assert_response :unprocessable_entity
    end

    test "pdf returns application/pdf" do
      get pdf_api_song_path(303)
      assert_response :success
      assert_equal "application/pdf", response.media_type
      assert_match(/\A%PDF/, response.body)
      assert_includes response.headers["Content-Disposition"], "attachment"
      assert_includes response.headers["Content-Disposition"], "303-"
    end

    test "pdf is not found for missing song" do
      get pdf_api_song_path(999_999)
      assert_response :not_found
    end
  end
end
