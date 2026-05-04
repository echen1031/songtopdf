# frozen_string_literal: true

module Songbase
  # Minimal valid-enough PDF bytes so tests do not require Node / Puppeteer / Chrome.
  class GroverTestStub
    def initialize(_, **); end

    def to_pdf
      <<~PDF.strip
        %PDF-1.4
        1 0 obj<<>>endobj
        trailer<<>>
        %%EOF
      PDF
    end
  end
end
