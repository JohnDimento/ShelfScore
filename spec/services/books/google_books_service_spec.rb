require 'rails_helper'

RSpec.describe Books::GoogleBooksService do
  let(:service) { described_class.new }
  let(:books_api) { instance_double(Google::Apis::BooksV1::BooksService) }

  before do
    allow(Google::Apis::BooksV1::BooksService).to receive(:new).and_return(books_api)
    allow(books_api).to receive(:key=)
  end

  describe '#search' do
    let(:query) { 'Harry Potter' }
    let(:max_results) { 10 }
    let(:volume1) { double('volume1') }
    let(:volume2) { double('volume2') }
    let(:search_result) { double('search_result', items: [volume1, volume2]) }

    context 'when search is successful' do
      before do
        allow(books_api).to receive(:list_volumes)
          .with(query, max_results: max_results)
          .and_return(search_result)
      end

      it 'returns a success result with books' do
        result = service.search(query)
        expect(result[:success?]).to be true
        expect(result[:books]).to eq([volume1, volume2])
      end
    end

    context 'when search returns no results' do
      before do
        allow(books_api).to receive(:list_volumes)
          .with(query, max_results: max_results)
          .and_return(double('empty_result', items: nil))
      end

      it 'returns a success result with empty array' do
        result = service.search(query)
        expect(result[:success?]).to be true
        expect(result[:books]).to eq([])
      end
    end

    context 'when API raises an error' do
      before do
        allow(books_api).to receive(:list_volumes)
          .and_raise(Google::Apis::Error.new('API Error'))
      end

      it 'returns a failure result' do
        result = service.search(query)
        expect(result[:success?]).to be false
        expect(result[:error]).to include('Google Books API search error')
      end
    end
  end

  describe '#find_by_id' do
    let(:book_id) { 'book123' }
    let(:volume) { double('volume') }

    context 'when book is found' do
      before do
        allow(books_api).to receive(:get_volume)
          .with(book_id)
          .and_return(volume)
      end

      it 'returns a success result with the book' do
        result = service.find_by_id(book_id)
        expect(result[:success?]).to be true
        expect(result[:book]).to eq(volume)
      end
    end

    context 'when book is not found' do
      before do
        allow(books_api).to receive(:get_volume)
          .and_raise(Google::Apis::ClientError.new('Not found'))
      end

      it 'returns a failure result' do
        result = service.find_by_id(book_id)
        expect(result[:success?]).to be false
        expect(result[:error]).to include('Book not found')
      end
    end
  end

  describe '#import_book' do
    let(:book_id) { 'book123' }
    let(:volume) { double('volume', id: book_id) }
    let(:volume_info) do
      double('volume_info',
        title: 'Test Book',
        authors: ['Author Name'],
        description: 'Book description',
        published_date: '2020',
        page_count: 200,
        categories: ['Fiction'],
        average_rating: 4.5,
        ratings_count: 100,
        image_links: double('image_links', thumbnail: 'thumbnail.jpg'),
        preview_link: 'preview.html',
        industry_identifiers: [
          double('isbn13', type: 'ISBN_13', identifier: '9781234567890'),
          double('isbn10', type: 'ISBN_10', identifier: '1234567890')
        ]
      )
    end

    before do
      allow(service).to receive(:find_by_id)
        .with(book_id)
        .and_return(success?: true, book: double('volume', volume_info: volume_info))
    end

    context 'when book does not exist' do
      it 'creates a new book with correct attributes' do
        result = service.import_book(book_id)
        expect(result[:success?]).to be true

        book = result[:book]
        expect(book.title).to eq('Test Book')
        expect(book.author).to eq('Author Name')
        expect(book.description).to be_present
        expect(book.published_year).to eq(2020)
        expect(book.isbn_13).to eq('9781234567890')
        expect(book.isbn_10).to eq('1234567890')
      end
    end

    context 'when book already exists' do
      let!(:existing_book) { create(:book, google_books_id: book_id) }

      it 'updates the existing book' do
        result = service.import_book(book_id)
        expect(result[:success?]).to be true
        expect(result[:book].id).to eq(existing_book.id)
        expect(result[:book].title).to eq('Test Book')
      end
    end

    context 'when book fails to save' do
      before do
        allow_any_instance_of(Book).to receive(:save).and_return(false)
        allow_any_instance_of(Book).to receive_message_chain(:errors, :full_messages)
          .and_return(['Title is invalid'])
      end

      it 'returns a failure result' do
        result = service.import_book(book_id)
        expect(result[:success?]).to be false
        expect(result[:error]).to include('Failed to save book')
      end
    end

    context 'with missing or nil fields' do
      let(:volume_info_with_nils) do
        double('volume_info',
          title: nil,
          authors: nil,
          description: nil,
          published_date: nil,
          page_count: nil,
          categories: nil,
          average_rating: nil,
          ratings_count: nil,
          image_links: nil,
          preview_link: nil,
          industry_identifiers: []
        )
      end

      before do
        allow(service).to receive(:find_by_id)
          .with(book_id)
          .and_return(success?: true, book: double('volume', volume_info: volume_info_with_nils))
      end

      it 'fails gracefully when required fields are missing' do
        result = service.import_book(book_id)
        expect(result[:success?]).to be false
        expect(result[:error]).to include('Failed to save book')
      end
    end
  end

  describe '#import_books_by_query' do
    let(:query) { 'Harry Potter' }
    let(:volume1) { double('volume1', id: 'book1') }
    let(:volume2) { double('volume2', id: 'book2') }

    before do
      allow(service).to receive(:search)
        .with(query, max_results: 10)
        .and_return(success?: true, books: [volume1, volume2])
    end

    context 'when all books are imported successfully' do
      before do
        allow(service).to receive(:import_book)
          .with('book1')
          .and_return(success?: true, book: create(:book))
        allow(service).to receive(:import_book)
          .with('book2')
          .and_return(success?: true, book: create(:book))
      end

      it 'returns a success result with all imported books' do
        result = service.import_books_by_query(query)
        expect(result[:success?]).to be true
        expect(result[:books].length).to eq(2)
      end
    end

    context 'when search fails' do
      before do
        allow(service).to receive(:search)
          .and_return(success?: false, error: 'Search failed')
      end

      it 'returns the search failure result' do
        result = service.import_books_by_query(query)
        expect(result[:success?]).to be false
        expect(result[:error]).to eq('Search failed')
      end
    end

    context 'when some books fail to import' do
      before do
        allow(service).to receive(:import_book)
          .with('book1')
          .and_return(success?: true, book: create(:book))
        allow(service).to receive(:import_book)
          .with('book2')
          .and_return(success?: false, error: 'Import failed')
      end

      it 'returns only successfully imported books' do
        result = service.import_books_by_query(query)
        expect(result[:success?]).to be true
        expect(result[:books].length).to eq(1)
      end
    end
  end

  describe '#clean_description' do
    it 'handles nil description' do
      result = service.send(:clean_description, nil)
      expect(result).to be_nil
    end

    it 'removes HTML tags' do
      html = '<p>This is a <b>bold</b> description</p>'
      result = service.send(:clean_description, html)
      expect(result).to eq('This is a bold description')
    end

    it 'converts <br> tags to newlines' do
      html = 'Line 1<br>Line 2<br/>Line 3'
      result = service.send(:clean_description, html)
      expect(result).to eq("Line 1\nLine 2\nLine 3")
    end

    it 'removes extra whitespace' do
      html = '<p>Line 1</p>  \n\n  <p>Line 2</p>'
      result = service.send(:clean_description, html)
      expect(result).to eq("Line 1\n\nLine 2")
    end

    it 'handles complex HTML with nested elements' do
      html = '<div><h1>Title</h1><p>Para 1</p><br/><p>Para 2 with <i>italic</i> and <b>bold</b></p></div>'
      result = service.send(:clean_description, html)
      expect(result).to eq("Title\nPara 1\nPara 2 with italic and bold")
    end
  end
end
