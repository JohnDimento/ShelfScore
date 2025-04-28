require 'rails_helper'

RSpec.describe Quiz, type: :model do
  describe 'associations' do
    it { should belong_to(:book) }
    it { should have_many(:questions).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
  end
end
