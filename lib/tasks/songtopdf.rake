# frozen_string_literal: true

namespace :songtopdf do
  desc "Build chord songbook PDF to tmp/songbook.pdf (SONGBOOK_IDS=704,3952)"
  task export: :environment do
    ids = ENV.fetch("SONGBOOK_IDS", "704,3952").split(",").map(&:strip).reject(&:empty?).map(&:to_i)
    out = Rails.root.join("tmp", "songbook.pdf")
    path = Songbase::SongbookPdfGenerator.new(ids, output_path: out).write!(out)
    puts "Wrote #{path} (#{ids.size} songs)"
  end
end
