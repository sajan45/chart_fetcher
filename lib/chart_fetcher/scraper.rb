require "nokogiri"
require "open-uri"

module ChartFetcher
  module Scraper

    SELECTORS = {
      title: '#title-overview-widget > div.vital > div.title_block > div > div.titleBar > div.title_wrapper > h1',
      movie_release_year: '#titleYear',
      imdb_rating: '#title-overview-widget > div.vital > div.title_block > div > div.ratings_wrapper > div.imdbRating > div.ratingValue > strong > span',
      summary: '#title-overview-widget > div.plot_summary_wrapper > div.plot_summary > div.summary_text',
      duration: '#title-overview-widget > div.vital > div.title_block > div > div.titleBar > div.title_wrapper > div.subtext',
      genre: '#title-overview-widget > div.vital > div.title_block > div > div.titleBar > div.title_wrapper > div.subtext'
    }
    def scrape(address, items_count)
      doc = Nokogiri::HTML(URI.open(address))
      top_links = get_movie_links(doc, items_count)
      fetch_data_from_links(top_links)
    end

    def get_movie_links(doc, items_count)
      count = 0
      links = []
      doc.css('#main > div > span > div > div > div.lister > table > tbody > tr').each do |movie_row|
        break if count == items_count
        links << movie_row.css('td.titleColumn > a').attribute('href').value
        count += 1
      end
      links
    end

    def fetch_data_from_links(links)
      result = []
      links.each do |link|
        link = "https://www.imdb.com" + link # originally link is just a path, without host name
        link_doc = Nokogiri::HTML(URI.open(link))
        link_detail = {}
        SELECTORS.each do |attribute, selector|
          link_detail[attribute] = send("process_#{attribute.to_s}", link_doc, selector)
        end
        result << link_detail
      end
      result
    end

    def get_text_data(doc, selector)
      doc.css(selector).first&.text&.strip || ""
    end

    def process_title(doc, selector)
      doc.xpath('//*[@id="title-overview-widget"]/div[1]/div[2]/div/div[2]/div[2]/h1/text()')
         .text.strip[0..-2] # there is some encoded character at end of string, removing it
      # title_with_year = get_text_data(doc, selector)
      # title_with_year.split("(")[0] # assuming movie title don't have other parenthesis
    end

    def process_movie_release_year(doc, selector)
      year_in_parenthesis = get_text_data(doc, selector)
      year_in_parenthesis[1..-2]
    end

    def process_imdb_rating(doc, selector)
      get_text_data(doc, selector).to_f
    end

    def process_summary(doc, selector)
      alt_selector = '#title-overview-widget > div.posterWithPlotSummary > div.plot_summary_wrapper > div.plot_summary > div.summary_text'
      summary = get_text_data(doc, selector)
      if summary == ""
        summary = get_text_data(doc, alt_selector) # in some cases, there is a different html structure
      end
      summary
    end

    def process_duration(doc, selector)
      all_movie_data = get_text_data(doc, selector)
      all_movie_data.split("|")[1].strip
    end

    def process_genre(doc, selector)
      all_movie_data = get_text_data(doc, selector)
      all_movie_data.split("|")[2].strip.gsub("\n", '')
    end
  end
end
