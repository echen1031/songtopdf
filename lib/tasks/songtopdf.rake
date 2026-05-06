# frozen_string_literal: true

require "csv"

namespace :songtopdf do
  # Column index → starting song number
  CSV_COLUMN_BASES = { 0 => 1, 1 => 100, 2 => 200, 3 => 300 }.freeze
  CSV_PATH = Rails.root.join("data", "ssot_song_ids.csv")

  # A4 column height in "units" at 9pt / 1.35 line-height / 10mm margins:
  #   (297mm − 20mm) / (9pt × 1.35 × 0.3528 mm/pt) ≈ 64.5 → use 64
  COLUMN_HEIGHT_UNITS = 64.0

  desc "Build chord songbook PDF from data/ssot_song_ids.csv (or override with SONGBOOK_IDS=704,3952)"
  task export: :environment do
    if ENV["SONGBOOK_IDS"].present?
      entries      = ENV["SONGBOOK_IDS"].split(",").map(&:strip).reject(&:empty?).map { |raw| Songbase::SongbookPdfGenerator.parse_id_tune(raw) }
      toc_sections = nil
    else
      entries, toc_sections = entries_from_csv(CSV_PATH)
    end

    out  = Rails.root.join("tmp", "songbook.pdf")
    path = Songbase::SongbookPdfGenerator.new(entries: entries, toc_sections: toc_sections, output_path: out).write!(out)
    puts "Wrote #{path} (#{entries.size} songs)"
  end

  # ---------------------------------------------------------------------------

  # Returns [entries, toc_sections].
  # entries      – flat array of { id:, tune:, number: } for SongbookPdfGenerator
  # toc_sections – array of { name:, entries: [{ number:, title: }] } for TocHtmlGenerator
  def entries_from_csv(path)
    query        = Songbase::AppDataSongQuery.instance
    rows         = CSV.read(path, headers: true)
    headers      = rows.headers
    all_entries  = []
    toc_sections = []

    CSV_COLUMN_BASES.each do |col_idx, base|
      section_name = headers[col_idx].to_s
      section      = []

      rows.each do |row|
        cell = row[col_idx].to_s.strip
        next if cell.empty?

        parsed = Songbase::SongbookPdfGenerator.parse_id_tune(cell)
        song   = query.song(parsed[:id], tune: parsed[:tune])
        next unless song

        section << { parsed: parsed, height: estimate_height(song), title: song["title"].to_s }
      end

      ordered     = pack_section(section)
      toc_entries = []

      ordered.each_with_index do |item, idx|
        number = base + idx
        all_entries  << item[:parsed].merge(number: number)
        toc_entries  << { number: number, title: item[:title] }
      end

      toc_sections << { name: section_name, entries: toc_entries }
    end

    [all_entries, toc_sections]
  end

  # First Fit Decreasing bin-packing within one section.
  # Returns songs ordered bin-by-bin so sequential column fill is efficient.
  def pack_section(songs)
    sorted = songs.sort_by { |s| -s[:height] }
    bins   = []

    sorted.each do |item|
      target = bins.find { |b| b[:used] + item[:height] <= COLUMN_HEIGHT_UNITS }
      if target
        target[:songs] << item
        target[:used]  += item[:height]
      else
        bins << { songs: [item], used: item[:height] }
      end
    end

    bins.flat_map { |b| b[:songs] }
  end

  # Estimate song height in "units" (1 unit ≈ one 9pt plain lyric line).
  #
  # Line costs:
  #   blank line           → 0.35  (lyric-spacer)
  #   stanza number "1"    →  0    (merged into song-anchor, no extra spacing)
  #   stanza number 2+     → 1.95  (inter-block margin-top + padding-top)
  #   chord line (has "[") → 1.75  (chord rail + text row)
  #   plain lyric line     → 1.25
  #
  # Title overhead = 2.0 units (h2 height + bottom margin).
  def estimate_height(song)
    units         = 2.0
    stanza_count  = 0

    song["lyrics"].to_s.each_line do |raw|
      line = raw.chomp
      if line.strip.empty?
        units += 0.35
      elsif line.match?(/\A\s*\d+\s*\z/)
        stanza_count += 1
        units += 1.95 if stanza_count > 1  # each stanza after the first adds spacing
      elsif line.include?("[")
        units += 1.75
      else
        units += 1.25
      end
    end

    units
  end
end
