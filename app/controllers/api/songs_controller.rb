# frozen_string_literal: true

module Api
  class SongsController < ApplicationController
    # GET /api/songs/:id
    def show
      song = Songbase::AppDataSongQuery.instance.song(params[:id])
      if song
        render json: song
      else
        head :not_found
      end
    end

    # POST /api/songs/lookup  JSON: { "ids": [303, 304] }
    def lookup
      ids = params[:ids]
      unless ids.is_a?(Array)
        render json: { error: "ids must be an array of integers" }, status: :unprocessable_entity
        return
      end

      render json: Songbase::AppDataSongQuery.instance.songs_payload(ids)
    end

    # GET /api/songs/:id/pdf
    def pdf
      song = Songbase::AppDataSongQuery.instance.song(params[:id])
      unless song
        head :not_found
        return
      end

      bytes = Songbase::SongPdfGenerator.new(song).generate
      send_data bytes,
                filename: pdf_filename(song),
                type: "application/pdf",
                disposition: "attachment"
    rescue Grover::Error => e
      Rails.logger.error("[Song PDF] #{e.class}: #{e.message}")
      render json: { error: "pdf_generation_failed", detail: e.message }, status: :service_unavailable
    end

    private

    def pdf_filename(song)
      base = song["title"].to_s.parameterize.presence || "song"
      "#{song['id']}-#{base}.pdf"
    end
  end
end
