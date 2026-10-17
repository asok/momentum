require "rails_helper"

RSpec.describe DestroyBook do
  describe ".call" do
    let(:book) { create(:book) }

    it "deletes a book and its returned booking history" do
      create(:booking, book: book, borrowed_at: 1.day.ago, returned_at: Time.current)

      expect { described_class.call(book: book) }.to change(Book, :count).by(-1).and change(Booking, :count).by(-1)
    end

    it "refuses to delete a book with an active booking" do
      create(:booking, book: book)

      expect { described_class.call(book: book) }.to raise_error(DestroyBook::AlreadyBorrowed, "Return the book before deleting it")
      expect(book.reload).to be_persisted
    end
  end
end
