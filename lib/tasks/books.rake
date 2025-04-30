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
end
