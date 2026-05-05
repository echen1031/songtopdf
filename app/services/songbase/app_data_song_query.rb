# frozen_string_literal: true

require "json"

module Songbase
  # Loads Songbase `app_data` JSON once and answers song lookups by id.
  # Song objects match the keys and shape stored in the file (API-compatible).
  class AppDataSongQuery
    class << self
      def instance
        @instance ||= new
      end

      def reset!
        @instance = nil
      end
    end

    def initialize(path: Rails.application.config.songbase_app_data_path)
      @path = path.to_s
    end

    # Returns the song Hash as in the JSON file, or nil.
    # Pass +tune:+ (0 or 1) to extract a specific tune section from songs that
    # have multiple tunes separated by "### ..." headers in the lyrics.
    def song(id, tune: nil)
      raw = songs_by_id[id.to_i]
      return nil if raw.nil?

      tune.nil? ? raw : with_tune(raw, tune.to_i)
    end

    # Returns an Array of song Hashes in the order of +ids+; omits unknown ids.
    def songs(ids)
      Array(ids).map(&:to_i).filter_map { |i| songs_by_id[i] }
    end

    # Wraps matching songs like the upstream payload's `songs` key.
    def songs_payload(ids)
      { "songs" => songs(ids) }
    end

    private

    def songs_by_id
      @songs_by_id ||= load_index
    end

    def load_index
      raw = File.read(@path)
      data = JSON.parse(raw)
      list = data["songs"]
      raise Songbase::InvalidAppData, "missing songs array in #{@path}" unless list.is_a?(Array)

      list.each_with_object({}) do |song, idx|
        next unless song.is_a?(Hash) && song["id"]

        idx[song["id"].to_i] = song.freeze
      end.freeze
    end

    # Returns a copy of +song+ with lyrics replaced by the tune at +index+.
    # Splits lyrics on "### ..." section headers; falls back to last section if
    # index is out of range. Returns +song+ unchanged when only one section exists.
    def with_tune(song, index)
      sections = song["lyrics"].to_s.split(/(?:^|\n)(?=###)/).reject(&:empty?)
      return song if sections.size <= 1

      section = sections[index] || sections.last
      lyrics = section.lines.drop_while { |l| l.start_with?("###") }.join.lstrip
      song.merge("lyrics" => lyrics)
    end
  end

  class InvalidAppData < StandardError; end
end
