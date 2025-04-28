require 'google/apis/books_v1'
require 'action_view'
require 'nokogiri'

class GoogleBooksService
  include ActionView::Helpers::SanitizeHelper

  def initialize
    @books = Google::Apis::BooksV1::BooksService.new
    @books.key = ENV['GOOGLE_BOOKS_API_KEY']
  end

  def search(query, max_results: 10)
    @books.list_volumes(query, max_results: max_results).items || []
  end

  def find_by_id(google_books_id)
    @books.get_volume(google_books_id)
  rescue Google::Apis::ClientError => e
    Rails.logger.error "Google Books API error: #{e.message}"
    nil
  end

  def clean_description(html_description)
    return nil if html_description.nil?

    # Parse HTML and get text content
    doc = Nokogiri::HTML(html_description)

    # Replace <br> and <br/> with newlines
    doc.css('br').each { |br| br.replace("\n") }

    # Get text content and clean up extra whitespace
    text = doc.text.strip
    text.gsub(/\n\s*\n/, "\n\n")  # Replace multiple blank lines with a single blank line
  end

  def import_book(google_books_id)
    volume = find_by_id(google_books_id)
    return nil unless volume

    book = Book.find_or_initialize_by(google_books_id: google_books_id)
    volume_info = volume.volume_info

    book.assign_attributes(
      title: volume_info.title,
      author: volume_info.authors&.join(', '),
      description: clean_description(volume_info.description),
      published_year: volume_info.published_date&.to_i,
      isbn_13: volume_info.industry_identifiers&.find { |i| i.type == 'ISBN_13' }&.identifier,
      isbn_10: volume_info.industry_identifiers&.find { |i| i.type == 'ISBN_10' }&.identifier,
      page_count: volume_info.page_count,
      categories: volume_info.categories || [],
      average_rating: volume_info.average_rating,
      ratings_count: volume_info.ratings_count,
      thumbnail_url: volume_info.image_links&.thumbnail,
      preview_link: volume_info.preview_link
    )

    book.save
    book
  end

  def import_books_by_query(query, max_results: 10)
    volumes = search(query, max_results: max_results)
    volumes.map { |volume| import_book(volume.id) }.compact
  end
end
