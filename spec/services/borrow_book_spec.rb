require "rails_helper"

RSpec.describe BorrowBook do
  describe ".call" do
    let(:book) { create(:book) }
    let(:user) { create(:user) }

    it "creates an active booking" do
      expect { described_class.call(book: book, user: user) }.to change { book.bookings.where(returned_at: nil).count }.by(1)
    end

    it "rejects borrowing when the book has an active booking" do
      create(:booking, book: book)

      expect { described_class.call(book: book, user: user) }.to raise_error(BorrowBook::AlreadyBorrowed)
    end

    it "allows borrowing again after the book is returned" do
      create(:booking, book: book, borrowed_at: 2.days.ago, returned_at: 1.day.ago)

      expect { described_class.call(book: book, user: user) }.to change { book.bookings.where(returned_at: nil).count }.by(1)
    end
  end
end
