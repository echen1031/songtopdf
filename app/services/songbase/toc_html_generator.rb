# frozen_string_literal: true

require "erb"

module Songbase
  # Builds an HTML table of contents divided by section.
  #
  # Usage:
  #   sections = [
  #     { name: "General Songs",  entries: [{ number: 1,   title: "Father Abraham" }, ...] },
  #     { name: "Songs on The Triune God", entries: [{ number: 101, title: "..." }, ...] },
  #     ...
  #   ]
  #   Songbase::TocHtmlGenerator.new(sections).build  # => HTML String (html_safe)
  class TocHtmlGenerator
    def initialize(sections)
      @sections = sections
    end

    def build
      html = +""
      html << %(<div class="toc">\n)
      html << %(<h1 class="toc-title">Songs</h1>\n)
      html << %(<div class="toc-cols">\n)

      @sections.each do |section|
        next if section[:entries].empty?

        html << %(<section class="toc-section">\n)
        html << %(<h2 class="toc-section-name">#{h(section[:name])}</h2>\n)
        html << %(<ul class="toc-list">\n)

        section[:entries].each do |entry|
          html << %(<li class="toc-entry">)
          html << %(<span class="toc-num">Song #{entry[:number]}</span>)
          html << %(<span class="toc-name">#{h(entry[:title])}</span>)
          html << %(</li>\n)
        end

        html << %(</ul>\n)
        html << %(</section>\n)
      end

      html << %(</div>\n)
      html << %(</div>\n)
      html.html_safe
    end

    private

    def h(str)
      ERB::Util.html_escape(str.to_s)
    end
  end
end
