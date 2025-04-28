namespace :books do
  desc 'Import books from Google Books API'
  task import: :environment do
    service = GoogleBooksService.new

    # Break queries into smaller batches
    query_batches = [
      # Batch 1 - Contemporary
      ['contemporary fiction', 'literary fiction', 'modern bestsellers'],
      # Batch 2 - Mysteries
      ['cozy mystery', 'detective fiction', 'crime novels'],
      # Batch 3 - Romance
      ['historical romance', 'romantic comedy', 'paranormal romance'],
      # Batch 4 - Fantasy
      ['epic fantasy', 'urban fantasy', 'young adult fantasy'],
      # Batch 5 - Science Fiction
      ['space opera', 'cyberpunk', 'science fiction classics'],
      # Batch 6 - Non-Fiction
      ['popular science', 'business leadership', 'self improvement'],
      # Batch 7 - Award Winners
      ['nobel prize literature', 'man booker prize', 'costa book awards'],
      # Batch 8 - Genres
      ['psychological thriller', 'horror fiction', 'magical realism'],
      # Batch 9 - Children/YA
      ['middle grade fiction', 'young adult contemporary', 'picture books'],
      # Batch 10 - Specific Topics
      ['climate change books', 'artificial intelligence', 'world history']
    ]

    total_imported = 0

    query_batches.each_with_index do |batch, batch_index|
      puts "\nStarting batch #{batch_index + 1}"

      batch.each do |query|
        puts "\nImporting books for query: #{query}"
        begin
          # Reduce books per query to 10 to avoid hitting limits
          books = service.import_books_by_query(query, max_results: 10)
          total_imported += books.count
          puts "Imported #{books.count} books for '#{query}'"

          # Add a short delay between queries in the same batch
          puts "Short pause between queries..."
          sleep 30
        rescue => e
          puts "Error importing books for '#{query}': #{e.message}"
          # Add a longer delay if we hit an error
          puts "Longer pause after error..."
          sleep 120
        end
      end

      # Add a longer delay between batches
      unless batch_index == query_batches.size - 1
        puts "\nTaking a break between batches (180 seconds)..."
        sleep 180
      end
    end

    puts "\nTotal books imported: #{total_imported}"
    puts "\nRunning description cleanup..."
    Rake::Task["books:clean_descriptions"].invoke
  end

  desc 'Clean HTML tags from existing book descriptions'
  task clean_descriptions: :environment do
    service = GoogleBooksService.new
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
