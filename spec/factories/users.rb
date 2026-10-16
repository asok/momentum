FactoryBot.define do
  factory :user do
    sequence(:card_number) { |n| format("%06d", n) }
    full_name { "Ada Lovelace" }
    sequence(:email) { |n| "reader#{n}@example.com" }
  end
end
