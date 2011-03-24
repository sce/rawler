module Rawler
  
  class Crawler
    
    attr_accessor :url, :links

    SKIP_FORMATS = /^(javascript|mailto)/

    def initialize(url)
      @url = url.strip
    end
    
    def links
      if different_domain?(url, Rawler.url) || not_html?(url)
        return []
      end
      
      response = Rawler::Request.get(url)
      
      doc = Nokogiri::HTML(response.body)
      doc.css('a').map { |a| a['href'] }.select { |url| !url.nil? }.map { |url| absolute_url(url) }.select { |url| valid_url?(url) }
    rescue Errno::ECONNREFUSED # TODO: add called from
      write("Couldn't connect to #{url}")
      []
    rescue Errno::ETIMEDOUT # TODO: add called from
      write("Connection to #{url} timed out")
      []
    end
    
    private
    
    def absolute_url(path)
      path = URI.encode(path.strip)
      if path[0].chr == '/'
        URI.parse(url).merge(path.to_s).to_s
      elsif URI.parse(path).scheme.nil?
        URI.parse(url).merge("/#{path.to_s}").to_s
      else
        path
      end
    rescue URI::InvalidURIError
      write("Invalid url: #{path} - Called from: #{url}")
      nil
    end
    
    # TODO: add 'called from in a more pragmatic way as an optional parameter
    def write(message)
      Rawler.output.error(message)
    end
        
    def different_domain?(url_1, url_2)
      URI.parse(url_1).host != URI.parse(url_2).host
    end
    
    def not_html?(url)
      Rawler::Request.head(url).content_type != 'text/html'
    end
    
    def valid_url?(url)
      return false unless url
      
      url.strip!
      scheme = URI.parse(url).scheme
      
      if ['http', 'https'].include?(scheme)
        true
      else
        write("Invalid url - #{url}") unless url =~ SKIP_FORMATS
        false
      end

    rescue URI::InvalidURIError
      false
       write("Invalid url - #{url}")
    end
      
  end
  
end
