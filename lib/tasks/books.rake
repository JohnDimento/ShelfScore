namespace :books do
  desc 'Import modern books from Google Books API'
  task import_modern: :environment do
    service = Books::GoogleBooksService.new

    # Modern book queries focused on recent publications
    query_batches = [
      # Contemporary Fiction
      ['2024 bestsellers', 'new releases fiction 2024', '2023 bestselling novels'],
      # Modern Genre Fiction
      ['contemporary thriller 2024', 'modern romance 2024', 'contemporary fantasy 2024'],
      # Popular Modern Authors
      ['Colleen Hoover', 'Taylor Jenkins Reid', 'Emily Henry'],
      # Book Prize Winners
      ['booker prize 2023', 'goodreads choice 2023', 'national book award 2023'],
      # Modern Non-Fiction
      ['2024 business books', '2024 self help', 'modern psychology books']
    ]

    total_imported = 0

    query_batches.each_with_index do |batch, batch_index|
      puts "\nStarting batch #{batch_index + 1}"

      batch.each do |query|
        puts "\nImporting books for query: #{query}"
        begin
          # Import more books per query (20 instead of 10)
          books = service.import_books_by_query(query, max_results: 20)
          total_imported += books.count
          puts "Imported #{books.count} books for '#{query}'"

          # Minimal delay between queries
          sleep 5
        rescue => e
          puts "Error importing books for '#{query}': #{e.message}"
          sleep 30  # Shorter recovery time after error
        end
      end

      # Shorter delay between batches
      unless batch_index == query_batches.size - 1
        puts "\nBrief pause between batches..."
        sleep 30
      end
    end

    puts "\nTotal modern books imported: #{total_imported}"
    puts "\nRunning description cleanup..."
    Rake::Task["books:clean_descriptions"].invoke
  end

  desc 'Clean HTML tags from existing book descriptions'
  task clean_descriptions: :environment do
    service = Books::GoogleBooksService.new
    total = Book.count
    cleaned = 0

    Book.find_each do |book|
      next if book.description.nil?

      cleaned_description = service.clean_description(book.description)
      if book.update(description: cleaned_description)
        cleaned += 1
        puts "Cleaned description for: #{book.title}"
      end
    end

    puts "\nCleaned #{cleaned} out of #{total} book descriptions"
  end

  desc 'Import books with retries and smart delays'
  task retry_import: :environment do
    max_retries = 3
    retry_count = 0

    begin
      Rake::Task["books:import"].invoke
    rescue => e
      retry_count += 1
      if retry_count <= max_retries
        puts "\nError occurred: #{e.message}"
        puts "Waiting 5 minutes before retry #{retry_count}/#{max_retries}..."
        sleep 300
        Rake::Task["books:import"].reenable
        retry
      else
        puts "\nFailed after #{max_retries} retries. Please try again later."
      end
    end
  end

  desc 'Bulk import large number of books from Google Books API'
  task bulk_import: :environment do
    service = Books::GoogleBooksService.new
    total_imported = 0

    # Comprehensive genre and category queries
    categories = {
      'Fiction' => [
        'fiction', 'novels', 'contemporary fiction', 'literary fiction',
        'mystery', 'thriller', 'romance', 'science fiction', 'fantasy',
        'historical fiction', 'horror', 'adventure', 'classics'
      ],
      'Non-Fiction' => [
        'non-fiction', 'biography', 'history', 'science', 'philosophy',
        'psychology', 'business', 'self-help', 'travel', 'cooking',
        'art', 'technology', 'politics', 'economics'
      ],
      'Academic' => [
        'textbook', 'academic', 'research', 'education', 'mathematics',
        'physics', 'chemistry', 'biology', 'engineering', 'computer science'
      ],
      'Children & Young Adult' => [
        'children books', 'young adult', 'middle grade', 'picture books',
        'teen fiction', 'juvenile literature'
      ]
    }

    # Track progress
    total_queries = categories.values.flatten.size
    current_query = 0

    categories.each do |category, queries|
      puts "\nStarting category: #{category}"

      queries.each do |query|
        current_query += 1
        puts "\nProcessing query #{current_query}/#{total_queries}: #{query}"

        # Try to get multiple pages of results
        start_index = 0
        books_found = true
        retries = 0
        max_retries = 3

        while books_found && start_index < 1000 # Google Books API limit
          begin
            puts "Fetching results starting at index #{start_index}..."

            # Get maximum allowed books per request (40 is Google Books API max)
            books = service.import_books_by_query(
              query,
              max_results: 40,
              start_index: start_index
            )

            if books.any?
              total_imported += books.count
              puts "Imported #{books.count} books (Total: #{total_imported})"
              start_index += books.count

              # Small delay to avoid rate limiting
              sleep 3
            else
              books_found = false
            end

            retries = 0
          rescue => e
            retries += 1
            if retries <= max_retries
              puts "Error occurred: #{e.message}. Retry #{retries}/#{max_retries}..."
              sleep 30 * retries # Exponential backoff
              retry
            else
              puts "Failed after #{max_retries} retries, moving to next query"
              break
            end
          end
        end

        # Brief pause between queries
        sleep 5
      end
    end

    puts "\nBulk import completed!"
    puts "Total books imported: #{total_imported}"
    puts "\nRunning description cleanup..."
    Rake::Task["books:clean_descriptions"].invoke
  end
end
