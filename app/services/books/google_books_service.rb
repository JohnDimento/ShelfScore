# frozen_string_literal: true

require 'google/apis/books_v1'
require 'action_view'
require 'nokogiri'

module Books
  class GoogleBooksService < Base::Service
    include ActionView::Helpers::SanitizeHelper

    def initialize
      @books = Google::Apis::BooksV1::BooksService.new
      @books.key = ENV['GOOGLE_BOOKS_API_KEY']
    end

    def search(query, max_results: 10)
      result = @books.list_volumes(query, max_results: max_results)
      success(books: result.items || [])
    rescue Google::Apis::Error => e
      failure("Google Books API search error: #{e.message}")
    end

    def find_by_id(google_books_id)
      result = @books.get_volume(google_books_id)
      success(book: result)
    rescue Google::Apis::ClientError => e
      Rails.logger.error "Google Books API error: #{e.message}"
      failure("Book not found: #{e.message}")
    end

    def import_book(google_books_id)
      result = find_by_id(google_books_id)
      return result unless result.success?

      volume = result.book
      book = Book.find_or_initialize_by(google_books_id: google_books_id)
      volume_info = volume.volume_info

      book.assign_attributes(book_attributes(volume_info))

      if book.save
        success(book: book)
      else
        failure("Failed to save book: #{book.errors.full_messages.join(', ')}")
      end
    end

    def import_books_by_query(query, max_results: 10)
      search_result = search(query, max_results: max_results)
      return search_result unless search_result.success?

      imported_books = search_result.books.map { |volume| import_book(volume.id) }
      success(books: imported_books.select(&:success?).map(&:book))
    end

    private

    def book_attributes(volume_info)
      {
        title: volume_info.title,
        author: volume_info.authors&.join(', '),
        description: clean_description(volume_info.description),
        published_year: volume_info.published_date&.to_i,
        isbn_13: find_identifier(volume_info, 'ISBN_13'),
        isbn_10: find_identifier(volume_info, 'ISBN_10'),
        page_count: volume_info.page_count,
        categories: volume_info.categories || [],
        average_rating: volume_info.average_rating,
        ratings_count: volume_info.ratings_count,
        thumbnail_url: volume_info.image_links&.thumbnail,
        preview_link: volume_info.preview_link
      }
    end

    def find_identifier(volume_info, type)
      volume_info.industry_identifiers&.find { |i| i.type == type }&.identifier
    end

    def clean_description(html_description)
      return nil if html_description.nil?

      # Parse HTML and get text content
      doc = Nokogiri::HTML(html_description)

      # Replace <br> and <br/> with newlines
      doc.css('br').each { |br| br.replace("\n") }

      # Get text content and clean up extra whitespace
      text = doc.text.strip
      text.gsub(/\n\s*\n/, "\n\n") # Replace multiple blank lines with a single blank line
    end
  end
end
