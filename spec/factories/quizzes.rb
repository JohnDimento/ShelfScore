FactoryBot.define do
  factory :quiz do
    association :book
    title { "Quiz for #{book.title}" }
  end
end
