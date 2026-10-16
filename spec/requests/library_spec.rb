require "rails_helper"

RSpec.describe "Library API", type: :request do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:author) { create(:author, name: "A Writer") }
  let(:book) { create(:book, serial_number: "000001", title: "A Book", author: author) }
  let(:reader) { create(:user, card_number: "000123", full_name: "Ada Lovelace", email: "ada@example.com") }

  before { clear_enqueued_jobs }
  after { clear_enqueued_jobs }

  describe "POST /books" do
    it "creates a book" do
      post "/books", params: { book: { serial_number: "000001", title: "A Book", author: "A Writer" } }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("serial_number" => "000001", "author" => "A Writer", "status" => "available")
    end

    it "reuses an existing author for books by the same writer" do
      author
      post "/books", params: { book: { serial_number: "000002", title: "Another Book", author: "A Writer" } }

      expect(Book.last.author).to eq(author)
      expect(Author.count).to eq(1)
    end

    it "rejects a book without an author" do
      post "/books", params: { book: { serial_number: "000002", title: "Another Book" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects a duplicate or malformed serial number" do
      book
      post "/books", params: { book: { serial_number: "000001", title: "Another", author: "Writer" } }
      expect(response).to have_http_status(:unprocessable_entity)

      post "/books", params: { book: { serial_number: "123", title: "Another", author: "Writer" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "borrowing and returning" do
    it "lists status and complete history across multiple loans" do
      post "/books/#{book.id}/borrow", params: { card_number: reader.card_number }
      expect(response).to have_http_status(:created)
      get "/books"
      expect(response.parsed_body.find { |entry| entry.fetch("id") == book.id }).to include("status" => "borrowed")

      post "/books/#{book.id}/return"
      expect(response).to have_http_status(:ok)
      get "/books"
      expect(response.parsed_body.find { |entry| entry.fetch("id") == book.id }).to include("status" => "available")

      post "/books/#{book.id}/borrow", params: { card_number: reader.card_number }
      get "/books/#{book.id}"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("bookings").map { |entry| entry.fetch("returned_at").nil? }).to eq([ false, true ])
      expect(response.parsed_body.fetch("bookings").first).to include("reader" => { "card_number" => "000123", "full_name" => "Ada Lovelace", "email" => "ada@example.com" })
    end

    it "schedules reminders on day 27 and day 30" do
      travel_to Time.zone.parse("2026-10-16 12:00:00") do
        post "/books/#{book.id}/borrow", params: { card_number: reader.card_number }

        booking_arg = { "_aj_globalid" => book.bookings.last.to_global_id.to_s }
        expect(enqueued_jobs.map { |job| [ job[:job], job[:args], job[:at] ] }).to eq([
          [ BookReminderJob, [ booking_arg, "early" ], 27.days.from_now.to_f ],
          [ BookReminderJob, [ booking_arg, "due" ], 30.days.from_now.to_f ]
        ])
        expect(response.parsed_body.fetch("due_at")).to eq(30.days.from_now.iso8601(3))
      end
    end

    it "rejects another borrowing while the book is out" do
      post "/books/#{book.id}/borrow", params: { card_number: reader.card_number }
      post "/books/#{book.id}/borrow", params: { card_number: reader.card_number }

      expect(response).to have_http_status(:conflict)
      expect(book.bookings.count).to eq(1)
    end

    it "rejects returning an available book" do
      post "/books/#{book.id}/return"
      expect(response).to have_http_status(:conflict)
    end

    it "rejects a missing reader" do
      post "/books/#{book.id}/borrow", params: { card_number: "999999" }
      expect(response).to have_http_status(:not_found)
    end

    it "does not log reminders after a return" do
      post "/books/#{book.id}/borrow", params: { card_number: reader.card_number }
      post "/books/#{book.id}/return"

      log = StringIO.new
      original_logger = Rails.logger
      Rails.logger = ActiveSupport::Logger.new(log)
      BookReminderJob.perform_now(book.bookings.last, "due")
      expect(log.string).not_to include('"event":"book_reminder"')
    ensure
      Rails.logger = original_logger
    end

    it "logs the email payload for an open booking" do
      post "/books/#{book.id}/borrow", params: { card_number: reader.card_number }

      log = StringIO.new
      original_logger = Rails.logger
      Rails.logger = ActiveSupport::Logger.new(log)
      BookReminderJob.perform_now(book.bookings.last, "early")
      expect(log.string).to include('"to":["ada@example.com"]')
    ensure
      Rails.logger = original_logger
    end
  end

  describe "DELETE /books/:id" do
    it "removes a returned book and its history" do
      post "/books/#{book.id}/borrow", params: { card_number: reader.card_number }
      post "/books/#{book.id}/return"
      delete "/books/#{book.id}"

      expect(response).to have_http_status(:no_content)
      expect(Booking.count).to eq(0)
    end

    it "refuses to delete an active loan" do
      post "/books/#{book.id}/borrow", params: { card_number: reader.card_number }
      delete "/books/#{book.id}"
      expect(response).to have_http_status(:conflict)
    end
  end

  describe "GET /books/:id" do
    it "returns 404 for a missing book" do
      get "/books/999999"
      expect(response).to have_http_status(:not_found)
    end
  end
end
