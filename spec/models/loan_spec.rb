require "rails_helper"

RSpec.describe Loan, type: :model do
  describe "the active loan constraint" do
    let(:book) { create(:book) }
    let(:user) { create(:user) }

    it "allows only one loan without a returned_at timestamp per book" do
      create(:loan, book: book, user: user, borrowed_at: 2.days.ago)

      expect {
        create(:loan, book: book, user: user, borrowed_at: Time.current)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows another loan after the previous one has a returned_at timestamp" do
      create(:loan, book: book, user: user, borrowed_at: 2.days.ago, returned_at: 1.day.ago)

      expect {
        create(:loan, book: book, user: user, borrowed_at: Time.current)
      }.to change(Loan, :count).by(1)
    end
  end
end
