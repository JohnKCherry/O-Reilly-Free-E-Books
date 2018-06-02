# This script generates links for downloading free books from O'Reilly site (http://www.oreilly.com/programming/free)
# Requirements
# ruby
# httparty, nokogiri (gem install httparty nokogiri --no-ri --no-rdoc)
# Execute
# ruby script.rb > books.md

require 'httparty'
require 'nokogiri'
require 'uri'

module OReillySite
  URL    = 'http://www.oreilly.com/'
  THEME_TITLES = {
    'programming' => 'Programming',
    'iot' => 'IoT',
    'data' => 'Data',
    'webops-perf' => 'WebOps',
    'web-platform' => 'Web Development',
    'security' => 'Security',
    'business' => 'Business',
    'design' => 'Design'
    
  }
  THEMES = THEME_TITLES.keys

  FORMATS = ['pdf', 'epub', 'mobi']
end

module OReillySite::URLBuilder
  def self.theme_url(theme)
    OReillySite::URL + theme + '/' + 'free/'
  end

  def self.download_url(theme, book_filename, format)
    theme_url(theme) + 'files/' + book_filename + '.' + format
  end
end

module OReillySite::Crawler
  def self.library
    books = Hash.new { |hash, key| hash[key] = [] }
    
    OReillySite::THEMES.each do |t|
      books[t] = theme_books(OReillySite::URLBuilder.theme_url(t))
    end
    
    books
  end
  
  private
  
  def self.theme_books(theme_url)
    Nokogiri.HTML(HTTParty.get(theme_url).body)
      .css("section .product-row a")
      .map { |link| get_book_info(link) }
  end

  def self.get_book_info(link)
    splitted_url = URI(link.attributes['href'].value).path.split('/')
    
    OpenStruct.new(
      theme:     splitted_url[1],
      title:     link.attributes['title'].value,
      file_name: splitted_url.last.split('.').first
    )
  end
end

def markdown(library)
  main_header = "# Free Programming Ebooks - O'Reilly Media \n"
  head_of_contents = ["## Categories"]
  theme_sections = []  
  
  library.each do |theme, books|
    theme_title = OReillySite::THEME_TITLES[theme]
    theme_link = URI.escape(theme_title.downcase.sub ' ', '-')

    head_of_contents << "- [#{theme_title}](##{theme_link})"
    
    section_header = "\n## #{theme_title} \n"

    section_books = books.map do |book|
      book_title =  "\n### #{book.title}"
      
      links = OReillySite::FORMATS.map do |fmt|
        "[#{fmt}](#{OReillySite::URLBuilder.download_url(book.theme, book.file_name, fmt)})"
      end.join(" ")

      [book_title, links].join("\n")
    end.join("\n")

    theme_sections << [section_header, section_books].join("\n")
  end


  [main_header, head_of_contents.join("\n"), theme_sections].join("\n")
end

def main
  puts markdown(OReillySite::Crawler.library)
end

main
