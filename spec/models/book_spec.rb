require 'rails_helper'

RSpec.describe Book, type: :model do
  describe 'associations' do
    it { should have_many(:quizzes).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:author) }
  end

  describe '.search' do
    let!(:book1) { create(:book, title: 'The Great Gatsby', author: 'F. Scott Fitzgerald') }
    let!(:book2) { create(:book, title: 'To Kill a Mockingbird', author: 'Harper Lee') }

    it 'finds books by title' do
      expect(Book.search('gatsby')).to include(book1)
      expect(Book.search('gatsby')).not_to include(book2)
    end

    it 'finds books by author' do
      expect(Book.search('fitzgerald')).to include(book1)
      expect(Book.search('fitzgerald')).not_to include(book2)
    end

    it 'is case insensitive' do
      expect(Book.search('GATSBY')).to include(book1)
      expect(Book.search('fitzgerald')).to include(book1)
    end
  end
end
