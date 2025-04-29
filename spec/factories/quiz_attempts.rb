FactoryBot.define do
  factory :quiz_attempt do
    user { nil }
    quiz { nil }
    score { "9.99" }
    last_attempt_at { "2025-04-28 19:40:33" }
  end
end
