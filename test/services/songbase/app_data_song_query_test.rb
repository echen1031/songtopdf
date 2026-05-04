# frozen_string_literal: true

require "test_helper"

module Songbase
  class AppDataSongQueryTest < ActiveSupport::TestCase
    setup { Songbase::AppDataSongQuery.reset! }

    test "song returns hash for known id" do
      song = Songbase::AppDataSongQuery.instance.song(303)
      assert_equal "Father Abraham", song["title"]
      assert_equal 303, song["id"]
    end

    test "song returns nil for unknown id" do
      assert_nil Songbase::AppDataSongQuery.instance.song(999_999)
    end

    test "songs preserves request order and skips unknown" do
      list = Songbase::AppDataSongQuery.instance.songs([304, 999, 303])
      assert_equal [304, 303], list.map { |s| s["id"] }
    end

    test "songs_payload wraps like API" do
      payload = Songbase::AppDataSongQuery.instance.songs_payload([303])
      assert_equal [303], payload["songs"].map { |s| s["id"] }
    end
  end
end
