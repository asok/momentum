FactoryBot.define do
  factory :loan do
    book
    user
    borrowed_at { Time.current }
  end
end
