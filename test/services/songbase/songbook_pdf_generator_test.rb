# frozen_string_literal: true

require "test_helper"

module Songbase
  class SongbookPdfGeneratorTest < ActiveSupport::TestCase
    setup { Songbase::AppDataSongQuery.reset! }

    test "write creates tmp pdf and orders songs by id list" do
      path = Rails.root.join("tmp", "songbook_test_output.pdf")
      FileUtils.rm_f(path)
      Songbase::SongbookPdfGenerator.new([704, 3952], output_path: path).write!(path)
      assert_path_exists path
      assert_operator File.size(path), :>, 10
      html = Songbase::SongbookPdfGenerator.new([704, 3952]).send(:render_html)
      assert_includes html, "Song 1"
      assert_includes html, "Christ"
      assert_not html.include?("Test songbook A")
      assert_includes html, "Song 2"
      assert_includes html, "Blessing"
      assert_not html.include?("Test songbook B")
      assert_includes html, "column-count: 3"
    ensure
      FileUtils.rm_f(path)
    end

    test "raises when id missing" do
      assert_raises(Songbase::SongNotFound) do
        Songbase::SongbookPdfGenerator.new([999_999]).generate
      end
    end
  end
end
