FactoryBot.define do
  factory :booking do
    book
    user
    borrowed_at { Time.current }
  end
end
