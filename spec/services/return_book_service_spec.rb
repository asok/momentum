require "rails_helper"

RSpec.describe ReturnBook do
  describe ".call" do
    let(:book) { create(:book) }

    it "marks the active loan as returned" do
      loan = create(:loan, book: book)

      expect { described_class.call(book: book) }.to change { loan.reload.returned_at }.from(nil)
    end

    it "rejects returning a book without an active loan" do
      expect { described_class.call(book: book) }.to raise_error(ReturnBook::NotBorrowed)
    end
  end
end
