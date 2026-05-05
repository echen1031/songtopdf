# frozen_string_literal: true

module Songbase
  # Builds one PDF from an ordered list of song ids (3-column HTML, chord-over-word lyrics).
  #
  # Pass plain ids:   SongbookPdfGenerator.new([704, "531?tune=1"])
  # Pass pre-numbered entries (e.g. from CSV):
  #   SongbookPdfGenerator.new(entries: [{ id: 750, tune: nil, number: 1 }, ...])
  class SongbookPdfGenerator
    DEFAULT_OUTPUT = -> { Rails.root.join("tmp", "songbook.pdf") }

    def initialize(ids = nil, output_path: nil, grover_class: nil, entries: nil)
      @entries = if entries
        entries
      else
        Array(ids).map { |raw| self.class.parse_id_tune(raw.to_s) }
      end
      @output_path = output_path || DEFAULT_OUTPUT.call
      @grover_class = grover_class || default_grover_class
    end

    # Parses "531?tune=1" → { id: 531, tune: 1 }; "531" → { id: 531, tune: nil }
    def self.parse_id_tune(str)
      if (m = str.match(/\A(\d+)\?tune=(\d+)\z/))
        { id: m[1].to_i, tune: m[2].to_i }
      else
        { id: str.to_i, tune: nil }
      end
    end

    def songs_payload
      query = Songbase::AppDataSongQuery.instance
      @entries.map.with_index(1) do |entry, auto_index|
        song = query.song(entry[:id], tune: entry[:tune])
        raise Songbase::SongNotFound, "Unknown song id: #{entry[:id]}" unless song

        { index: entry[:number] || auto_index, song: song }
      end
    end

    def generate
      html = render_html
      @grover_class.new(html).to_pdf
    end

    def write!(path = @output_path)
      path = Pathname(path)
      path.parent.mkpath
      File.binwrite(path, generate)
      path.to_s
    end

    private

    def default_grover_class
      Songtopdf.song_pdf_grover_class || Grover
    end

    def render_html
      ActionController::Base.render(
        template: "pdf/songbook/show",
        layout: "pdf_songbook",
        assigns: { songs: songs_payload }
      )
    end
  end
end
