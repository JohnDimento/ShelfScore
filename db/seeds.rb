# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Percy Jackson & the Olympians series
percy_jackson_books = [
  {
    title: "The Lightning Thief",
    author: "Rick Riordan",
    series: "Percy Jackson & the Olympians",
    description: "Percy Jackson discovers he is a demigod and must prevent a war between the Greek gods.",
    published_year: 2005
  },
  {
    title: "The Sea of Monsters",
    author: "Rick Riordan",
    series: "Percy Jackson & the Olympians",
    description: "Percy must save Camp Half-Blood by finding the Golden Fleece in the Sea of Monsters.",
    published_year: 2006
  },
  {
    title: "The Titan's Curse",
    author: "Rick Riordan",
    series: "Percy Jackson & the Olympians",
    description: "Percy and his friends must rescue Artemis and Annabeth from the Titans.",
    published_year: 2007
  },
  {
    title: "The Battle of the Labyrinth",
    author: "Rick Riordan",
    series: "Percy Jackson & the Olympians",
    description: "Percy and his friends navigate Daedalus's Labyrinth to prevent an invasion.",
    published_year: 2008
  },
  {
    title: "The Last Olympian",
    author: "Rick Riordan",
    series: "Percy Jackson & the Olympians",
    description: "Percy leads the final battle to protect Mount Olympus from Kronos and his army.",
    published_year: 2009
  }
]

# Create books and associated quizzes
percy_jackson_books.each do |book_data|
  book = Book.create!(book_data)

  # Create one quiz per book
  Quiz.create!(
    book: book,
    title: "#{book.title} Quiz",
    difficulty: "Medium"
  )
end
