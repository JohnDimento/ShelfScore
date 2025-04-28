FactoryBot.define do
  factory :question do
    association :quiz
    content { Faker::Lorem.question }
    options { 4.times.map { Faker::Lorem.sentence } }
    correct_answer { %w[A B C D].sample }
  end
end
