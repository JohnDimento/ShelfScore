FactoryBot.define do
  factory :quiz_attempt do
    association :user
    association :quiz
    score { rand(0..100) }
    last_attempt_at { Time.current }
  end
end
