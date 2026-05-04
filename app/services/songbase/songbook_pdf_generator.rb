# frozen_string_literal: true

module Songbase
  # Builds one PDF from an ordered list of song ids (3-column HTML, chord-over-word lyrics).
  class SongbookPdfGenerator
    DEFAULT_OUTPUT = -> { Rails.root.join("tmp", "songbook.pdf") }

    def initialize(ids, output_path: nil, grover_class: nil)
      @ids = Array(ids).map(&:to_i)
      @output_path = output_path || DEFAULT_OUTPUT.call
      @grover_class = grover_class || default_grover_class
    end

    def songs_payload
      query = Songbase::AppDataSongQuery.instance
      @ids.map.with_index(1) do |id, index|
        song = query.song(id)
        raise Songbase::SongNotFound, "Unknown song id: #{id}" unless song

        { index: index, song: song }
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
