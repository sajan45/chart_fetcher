require_relative './scraper'
require 'uri'
require 'json'

module ChartFetcher
  class CLI
    extend ChartFetcher::Scraper

    def self.process
      validate_inputs
      res = scrape(ARGV[0], ARGV[1].to_i)
      puts JSON.dump(res)
    end

    def self.validate_inputs
      if ARGV.length < 2
        raise 'Both URL and items count needed'
      elsif ARGV[1].to_i == 0
        raise 'Item count be should be an integer and more than 0'
      end

      begin
        uri = URI.parse(ARGV[0])
        unless uri.is_a?(URI::HTTP) && !uri.host.nil?
          raise 'chart_url is not a valid URL'
        end
      rescue URI::InvalidURIError
        raise 'chart_url is not a valid URL'
      end

      reg = /https?:\/\/(www\.)*imdb\.com\/india\/.+/
      unless ARGV[0].match?(reg)
        raise 'chart_url is not a imdb indian chart'
      end
    end
  end
end
