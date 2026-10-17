FactoryBot.define do
  factory :book do
    sequence(:serial_number) { |n| format("%06d", n) }
    title { "A Book" }
    author { "A Writer" }
  end
end
