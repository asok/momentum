require "rails_helper"

RSpec.describe BookReminderMailer, type: :mailer do
  let(:author) { create(:author, name: "A Writer") }
  let(:book) { create(:book, serial_number: "000001", title: "A Book", author: author) }
  let(:reader) { create(:user, card_number: "000123", full_name: "Ada Lovelace", email: "ada@example.com") }
  let(:booking) { create(:booking, book: book, user: reader, borrowed_at: Time.zone.parse("2026-10-16 12:00:00")) }
  let(:body) { "Hello Ada Lovelace,\n\nPlease return A Book (000001) by 2026-11-15.\n" }

  describe ".early_reminder" do
    it "builds a reminder three days before the due date" do
      message = described_class.early_reminder(booking)

      expect(message).to have_attributes(
        to: [ "ada@example.com" ],
        subject: "Your library book is due in 3 days",
        body: have_attributes(decoded: body)
      )
    end
  end

  describe ".late_reminder" do
    it "builds a reminder for the due date" do
      message = described_class.late_reminder(booking)

      expect(message).to have_attributes(
        to: [ "ada@example.com" ],
        subject: "Your library book is due today",
        body: have_attributes(decoded: body)
      )
    end
  end
end
