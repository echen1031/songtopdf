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
      pending_chorus_gap = false

      while i < lines.length
        line = lines[i]

        if line.strip.empty?
          out << render_spacer
          pending_chorus_gap = true if stanza_open
          i += 1
          next
        end

        if stanza_only?(line)
          out << close_chorus(chorus_open)
          chorus_open = false
          out << close_stanza(stanza_open)
          stanza_open = false
          pending_chorus_gap = false

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
            if pending_chorus_gap && !chorus_open
              out << %(<div class="stanza-section-br"><br></div>\n)
            end
            pending_chorus_gap = false
            unless chorus_open
              out << %(<div class="chorus-block">\n)
              chorus_open = true
            end
            out << render_line(line)
          else
            out << close_chorus(chorus_open)
            chorus_open = false
            pending_chorus_gap = false
            out << render_line(line)
          end
          i += 1
        else
          pending_chorus_gap = false
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
        inner = parse_segments(line).map { |seg| render_segment(seg) }.join
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

    def render_segment(seg)
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
      %(<span class="cw"><span class="ch">#{chord_inner}</span><span class="txt">#{text_inner}</span></span>)
    end

    def h(str)
      ERB::Util.html_escape(str)
    end
  end
end
