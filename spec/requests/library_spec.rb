require "rails_helper"

RSpec.describe "Library API", type: :request do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:book) { create(:book, serial_number: "000001", title: "A Book", author: "A Writer") }
  let(:reader) { create(:user, card_number: "000123", full_name: "Ada Lovelace", email: "ada@example.com") }

  before { clear_enqueued_jobs }
  after { clear_enqueued_jobs }

  describe "POST /books" do
    it "creates a book" do
      post "/books", params: { book: { serial_number: "000001", title: "A Book", author: "A Writer" } }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("serial_number" => "000001", "author" => "A Writer", "status" => "available")
    end

    it "stores the author name on the book" do
      post "/books", params: { book: { serial_number: "000002", title: "Another Book", author: "A Writer" } }

      expect(Book.last.author).to eq("A Writer")
    end

    it "rejects a book without an author" do
      post "/books", params: { book: { serial_number: "000002", title: "Another Book" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(Book.count).to eq(0)
    end

    it "rejects a duplicate or malformed serial number" do
      book
      post "/books", params: { book: { serial_number: "000001", title: "Another", author: "Writer" } }
      expect(response).to have_http_status(:unprocessable_content)

      post "/books", params: { book: { serial_number: "123", title: "Another", author: "Writer" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /return" do
    context "when the book is borrowed" do
      let!(:booking) { create(:booking, book: book, user: reader) }

      it "returns the book and marks its booking as returned" do
        post "/books/#{book.id}/return"

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          "booking_id"  => booking.id,
          "returned_at" => booking.reload.returned_at.iso8601(3),
          "book"        => {
            "id"            => book.id,
            "serial_number" => "000001",
            "title"         => "A Book",
            "author"        => "A Writer",
            "status"        => "available"
          }
        )
      end
    end

    it "rejects returning an available book" do
      post "/books/#{book.id}/return"
      expect(response).to have_http_status(:conflict)
    end
  end

  describe "POST /borrow" do
    it "creates a booking and returns the borrowed book and reader" do
      post "/books/#{book.id}/borrow", params: { card_number: reader.card_number }

      booking = book.bookings.last
      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to eq(
        "booking_id"  => booking.id,
        "borrowed_at" => booking.borrowed_at.iso8601(3),
        "due_at"      => booking.due_at.iso8601(3),
        "book"        => {
          "id"            => book.id,
          "serial_number" => "000001",
          "title"         => "A Book",
          "author"        => "A Writer",
          "status"        => "borrowed"
        },
        "reader"      => {
          "card_number" => "000123",
          "full_name"   => "Ada Lovelace",
          "email"       => "ada@example.com"
        }
      )
    end

    it "schedules reminders on day 27 and day 30" do
      travel_to Time.zone.parse("2026-10-16 12:00:00") do
        post "/books/#{book.id}/borrow", params: { card_number: reader.card_number }

        booking = book.bookings.last

        expect(EarlyBookReminderJob)
          .to have_been_enqueued.with(booking).at(27.days.from_now).once
        expect(LaterBookReminderJob)
          .to have_been_enqueued.with(booking).at(30.days.from_now).once

        expect(response.parsed_body.fetch("due_at")).to eq(30.days.from_now.iso8601(3))
      end
    end

    context "when the book was previously returned" do
      let!(:previous_booking) { create(:booking, book: book, user: reader, borrowed_at: 1.day.ago, returned_at: Time.current) }

      it "enqueues reminders for the new booking" do
        post "/books/#{book.id}/borrow", params: { card_number: reader.card_number }

        booking = book.bookings.last
        expect(response).to have_http_status(:created)
        expect(EarlyBookReminderJob).to have_been_enqueued.with(booking).once
        expect(LaterBookReminderJob).to have_been_enqueued.with(booking).once
      end
    end

    context "when the book is already borrowed" do
      let!(:booking) { create(:booking, book: book, user: reader) }

      it "rejects another borrowing" do
        post "/books/#{book.id}/borrow", params: { card_number: reader.card_number }

        expect(response).to have_http_status(:conflict)
        expect(book.bookings.count).to eq(1)
      end
    end

    it "rejects a missing reader" do
      post "/books/#{book.id}/borrow", params: { card_number: "999999" }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /books/:id" do
    context "when the book has been returned" do
      let!(:booking) { create(:booking, book: book, user: reader, borrowed_at: 1.day.ago, returned_at: Time.current) }

      it "removes the book and its history" do
        delete "/books/#{book.id}"

        expect(response).to have_http_status(:no_content)
        expect(Booking.count).to eq(0)
      end
    end

    context "when the book is borrowed" do
      let!(:booking) { create(:booking, book: book, user: reader) }

      it "refuses to delete the book" do
        delete "/books/#{book.id}"

        expect(response).to have_http_status(:conflict)
      end
    end
  end

  describe "GET /books" do
    context "when a book is borrowed" do
      let!(:booking) { create(:booking, book: book, user: reader) }

      it "lists the book as borrowed" do
        get "/books"

        expect(response.parsed_body.find { |entry| entry.fetch("id") == book.id }).to eq(
          "id" => book.id, "serial_number" => "000001", "title" => "A Book",
          "author" => "A Writer", "status" => "borrowed"
        )
      end
    end

    context "when a book has been returned" do
      let!(:booking) { create(:booking, book: book, user: reader, borrowed_at: 1.day.ago, returned_at: Time.current) }

      it "lists the book as available" do
        get "/books"

        expect(response.parsed_body.find { |entry| entry.fetch("id") == book.id }).to include("status" => "available")
      end
    end
  end

  describe "GET /books/:id" do
    it "serializes a book with its booking history" do
      get "/books/#{book.id}"

      expect(response.parsed_body).to eq(
        "id"            => book.id,
        "serial_number" => "000001",
        "title"         => "A Book",
        "author"        => "A Writer",
        "status"        => "available",
        "bookings"      => []
      )
    end

    context "with multiple bookings" do
      let!(:first_booking) { create(:booking, book: book, user: reader, borrowed_at: 1.day.ago, returned_at: Time.current) }
      let!(:second_booking) { create(:booking, book: book, user: reader) }

      it "lists complete history with the returned booking first" do
        get "/books/#{book.id}"

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.fetch("bookings").map { |entry| entry.fetch("returned_at").nil? }).to eq([false, true])
        expect(response.parsed_body.fetch("bookings").first).to eq(
          "id"          => first_booking.id,
          "borrowed_at" => first_booking.borrowed_at.iso8601(3),
          "due_at"      => first_booking.due_at.iso8601(3),
          "returned_at" => first_booking.returned_at.iso8601(3),
          "reader"      => {
            "card_number" => "000123",
            "full_name"   => "Ada Lovelace",
            "email"       => "ada@example.com"
          }
        )
      end
    end

    it "returns 404 for a missing book" do
      get "/books/999999"
      expect(response).to have_http_status(:not_found)
    end
  end
end
