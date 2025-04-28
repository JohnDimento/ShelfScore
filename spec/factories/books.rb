FactoryBot.define do
  factory :book do
    title { Faker::Book.title }
    author { Faker::Book.author }
    series { [nil, Faker::Book.title].sample }
    description { Faker::Lorem.paragraph }
    published_year { rand(1900..2024) }
  end
end
