# frozen_string_literal: true

require "erb"

module Songbase
  # Songbase-style lyrics: chords in brackets above text; stanza digits merge onto the next line
  # with stanza-inline; indented lines (2+ spaces) as chorus. Wraps stanzas/choruses for PDF column breaks.
  class LyricsChordHtml
    Segment = Struct.new(:chord, :text, keyword_init: true)

    class << self
      def build(lyrics)
        new(lyrics.to_s).build
      end

      # Returns [head_html, tail_html].
      # head_html = everything up to and including the first stanza-block or
      # chorus-block (used to wrap the song title and first stanza together in
      # one break-inside:avoid container so they never get separated).
      # tail_html = everything after that first block.
      # If no block is found all lyrics land in head_html so they stay with the title.
      def build_split(lyrics)
        html = build(lyrics).to_s
        m = html.match(/<div class="(?:stanza|chorus)-block">/)
        return [html.html_safe, "".html_safe] unless m

        pos = m.end(0)
        depth = 1
        while depth > 0
          next_open  = html.index("<div", pos)
          next_close = html.index("</div>", pos)
          break unless next_close

          if next_open && next_open < next_close
            depth += 1
            pos = next_open + 4
          else
            depth -= 1
            pos = next_close + 6
          end
        end

        [html[0...pos].html_safe, html[pos..].html_safe]
      end
    end

    def initialize(lyrics)
      @lyrics = lyrics
    end

    def build
      lines = @lyrics.each_line.map(&:chomp)
      out = +""
      i = 0
      stanza_open = false
      chorus_open = false

      while i < lines.length
        line = lines[i]

        if line.strip.empty?
          out << render_spacer
          i += 1
          next
        end

        if stanza_only?(line)
          out << close_chorus(chorus_open)
          chorus_open = false
          out << close_stanza(stanza_open)
          stanza_open = false

          num = line.strip
          j = i + 1
          while j < lines.length && lines[j].strip.empty?
            out << render_spacer
            j += 1
          end

          if j >= lines.length
            out << render_stanza_orphan(num)
            i = j
            next
          end

          if stanza_only?(lines[j])
            out << render_stanza_orphan(num)
            i += 1
            next
          end

          out << %(<div class="stanza-block">\n)
          stanza_open = true
          out << render_line(lines[j], stanza_prefix: num)
          i = j + 1
          next
        end

        if stanza_open
          if chorus_line?(line)
            unless chorus_open
              out << %(<div class="chorus-block">\n)
              chorus_open = true
            end
            out << render_line(line)
          else
            out << close_chorus(chorus_open)
            chorus_open = false
            out << render_line(line)
          end
          i += 1
        else
          out << render_line(line)
          i += 1
        end
      end

      out << close_chorus(chorus_open)
      out << close_stanza(stanza_open)
      out.html_safe
    end

    private

    def close_chorus(open)
      open ? %(</div>\n) : +""
    end

    def close_stanza(open)
      open ? %(</div>\n) : +""
    end

    def stanza_only?(line)
      line.match?(/\A\s*\d+\s*\z/)
    end

    def chorus_line?(line)
      line.match?(/\A {2,}\S/)
    end

    def render_spacer
      %(<div class="lyric-spacer"></div>\n)
    end

    def stanza_prefix_span(num)
      %(<span class="stanza-inline">#{h(num)}.</span> )
    end

    def render_stanza_orphan(num)
      %(<div class="stanza-block"><div class="lyric-line lyric-plain">#{stanza_prefix_span(num)}</div></div>\n)
    end

    def render_line(line, stanza_prefix: nil)
      prefix = stanza_prefix ? stanza_prefix_span(stanza_prefix) : ""

      if line.match?(/\A\s*#/)
        return %(<div class="lyric-meta">#{prefix}#{h(line)}</div>\n)
      end

      if line.include?("[")
        segs  = parse_segments(line)
        inner = segs.each_with_index.map do |seg, idx|
          # A segment is "tight" (no trailing gap) when its text has no trailing
          # whitespace AND a next segment follows — i.e. the chord sits mid-word.
          next_seg = segs[idx + 1]
          tight = next_seg && seg.text.to_s != "" && !seg.text.match?(/[ \t]\z/)
          render_segment(seg, tight: tight)
        end.join
        return %(<div class="lyric-line chord-line">#{prefix}#{inner}</div>\n)
      end

      %(<div class="lyric-line lyric-plain">#{prefix}#{h(line)}</div>\n)
    end

    def parse_segments(line)
      segs = []
      i = 0
      n = line.length
      while i < n
        if line[i] == "["
          j = line.index("]", i + 1)
          break unless j

          chord = line[(i + 1)...j]
          i = j + 1
          k = i
          k += 1 while k < n && line[k] != "["
          text = line[i...k]
          segs << Segment.new(chord: chord, text: text)
          i = k
        else
          k = i
          k += 1 while k < n && line[k] != "["
          text = line[i...k]
          segs << Segment.new(chord: nil, text: text) if text.present?
          i = k
        end
      end
      segs
    end

    def render_segment(seg, tight: false)
      chord_inner = if seg.chord.nil? || seg.chord.empty?
        "&nbsp;"
      else
        h(seg.chord)
      end
      # Keep lyric row height when a chord has no following text on the same line (e.g. "[G]be[C]\n")
      text_inner = if seg.text.present?
        h(seg.text)
      elsif seg.chord.nil? || seg.chord.empty?
        ""
      else
        "&nbsp;"
      end
      css = tight ? "cw cw-tight" : "cw"
      %(<span class="#{css}"><span class="ch">#{chord_inner}</span><span class="txt">#{text_inner}</span></span>)
    end

    def h(str)
      ERB::Util.html_escape(str)
    end
  end
end
