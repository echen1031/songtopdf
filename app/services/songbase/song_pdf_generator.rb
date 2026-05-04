# frozen_string_literal: true

module Songbase
  # Renders a printable HTML view for one song, then runs Grover (Chromium) to produce a PDF.
  class SongPdfGenerator
    def initialize(song, grover_class: nil)
      @song = song
      @grover_class = grover_class || default_grover_class
    end

    def generate
      html = render_html
      @grover_class.new(html).to_pdf
    end

    private

    def default_grover_class
      Songtopdf.song_pdf_grover_class || Grover
    end

    def render_html
      # ActionController::API does not render templates the same way as Base; use Base for HTML/PDF.
      ActionController::Base.render(
        template: "pdf/songs/show",
        layout: "pdf",
        assigns: { song: @song }
      )
    end
  end
end
