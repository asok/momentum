require "rails_helper"

RSpec.describe Booking, type: :model do
  describe "the active booking constraint" do
    let(:book) { create(:book) }
    let(:user) { create(:user) }

    it "allows only one booking without a returned_at timestamp per book" do
      create(:booking, book: book, user: user, borrowed_at: 2.days.ago)

      expect {
        create(:booking, book: book, user: user, borrowed_at: Time.current)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows another booking after the previous one has a returned_at timestamp" do
      create(:booking, book: book, user: user, borrowed_at: 2.days.ago, returned_at: 1.day.ago)

      expect {
        create(:booking, book: book, user: user, borrowed_at: Time.current)
      }.to change(Booking, :count).by(1)
    end
  end
end
