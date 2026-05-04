# frozen_string_literal: true

require "test_helper"

module Songbase
  class SongPdfGeneratorTest < ActiveSupport::TestCase
    setup { Songbase::AppDataSongQuery.reset! }

    test "generate passes rendered html to grover" do
      song = Songbase::AppDataSongQuery.instance.song(303)
      received = []

      fake = Class.new do
        define_method(:initialize) do |html, **|
          received << html
        end
        define_method(:to_pdf) { "stub-pdf" }
      end

      out = Songbase::SongPdfGenerator.new(song, grover_class: fake).generate
      assert_equal "stub-pdf", out
      assert_includes received.first, song["title"]
      assert_includes received.first, "<!DOCTYPE html>"
    end
  end
end
