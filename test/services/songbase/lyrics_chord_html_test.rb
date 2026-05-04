# frozen_string_literal: true

require "test_helper"

module Songbase
  class LyricsChordHtmlTest < ActiveSupport::TestCase
    test "chords stack above following text segments" do
      html = Songbase::LyricsChordHtml.build("[G]Christ [C]has come")
      assert_includes html, 'class="cw"'
      assert_includes html, ">G<"
      assert_match(/Christ\s*<\/span>/, html)
      assert_includes html, ">C<"
      assert_match(/has come<\/span>/, html)
    end

    test "plain prefix before first chord" do
      html = Songbase::LyricsChordHtml.build("Father [D]Abraham")
      assert_includes html, ">Father <"
      assert_includes html, ">D<"
      assert_includes html, ">Abraham<"
    end

    test "stanza number on same line as first chord line inside stanza block" do
      html = Songbase::LyricsChordHtml.build("# Capo\n\n1\n[G]Line\nMore text")
      assert_includes html, 'class="lyric-meta"'
      assert_includes html, "Capo"
      assert_includes html, 'class="stanza-block"'
      assert_includes html, 'class="stanza-inline">1.<'
      assert_includes html, 'class="lyric-line chord-line"><span class="stanza-inline">1.</span> <span class="cw">'
      assert_includes html, ">G<"
      assert_includes html, ">Line<"
      assert_includes html, "More text"
    end

    test "plain line without brackets" do
      html = Songbase::LyricsChordHtml.build("No chords here")
      assert_includes html, "lyric-plain"
      assert_includes html, "No chords here"
    end

    test "empty brackets reserve chord row" do
      html = Songbase::LyricsChordHtml.build("[]Word")
      assert_includes html, 'class="ch"'
      assert_includes html, ">Word<"
    end

    test "two chords on one word line keep second chord slot" do
      html = Songbase::LyricsChordHtml.build("[G]be[C]")
      assert_operator html.scan("class=\"cw\"").size, :>=, 2
      assert_includes html, ">G<"
      assert_includes html, ">be<"
      assert_includes html, ">C<"
    end

    test "stanza merges with plain first line" do
      html = Songbase::LyricsChordHtml.build("2\nPlain verse")
      assert_includes html, 'class="stanza-inline">2.<'
      assert_includes html, "Plain verse"
    end

    test "blank before indented chorus adds section break and chorus block" do
      html = Songbase::LyricsChordHtml.build("1\n[G]verse\n\n  [C]chorus")
      assert_includes html, "stanza-section-br"
      assert_includes html, "chorus-block"
    end

    test "blank between verse lines does not add section break" do
      html = Songbase::LyricsChordHtml.build("1\n[G]a\n\n[G]b")
      assert_not html.include?("stanza-section-br")
    end
  end
end
