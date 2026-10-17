require "rails_helper"

RSpec.describe ReturnBook do
  describe ".call" do
    let(:book) { create(:book) }

    it "marks the active booking as returned" do
      booking = create(:booking, book: book)

      expect { described_class.call(book: book) }.to change { booking.reload.returned_at }.from(nil)
    end

    it "rejects returning a book without an active booking" do
      expect { described_class.call(book: book) }.to raise_error(ReturnBook::NotBorrowed)
    end
  end
end
