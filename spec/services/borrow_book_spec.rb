require "rails_helper"

RSpec.describe BorrowBook do
  describe ".call" do
    let(:book) { create(:book) }
    let(:user) { create(:user) }

    it "creates an active loan" do
      expect { described_class.call(book: book, user: user) }.to change { book.loans.where(returned_at: nil).count }.by(1)
    end

    it "rejects borrowing when the book has an active loan" do
      create(:loan, book: book)

      expect { described_class.call(book: book, user: user) }.to raise_error(BorrowBook::AlreadyBorrowed)
    end

    it "allows borrowing again after the book is returned" do
      create(:loan, book: book, borrowed_at: 2.days.ago, returned_at: 1.day.ago)

      expect { described_class.call(book: book, user: user) }.to change { book.loans.where(returned_at: nil).count }.by(1)
    end

    context "when a reminder cannot be enqueued" do
      before do
        allow(LaterBookReminderJob).to receive(:set).and_return(instance_double(ActiveJob::ConfiguredJob, perform_later: false))
      end

      it "raises an enqueue error" do
        expect { described_class.call(book: book, user: user) }
          .to raise_error(BorrowBook::ReminderEnqueueFailed, "Could not enqueue LaterBookReminderJob")
      end

      it "rolls back the loan" do
        expect do
          described_class.call(book: book, user: user)
        rescue BorrowBook::ReminderEnqueueFailed
          nil
        end.not_to change { book.loans.count }
      end
    end
  end
end
