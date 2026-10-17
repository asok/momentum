module ReturnBook
  extend self

  NotBorrowed = Class.new(StandardError)

  def call(book:)
    book.with_lock do
      booking = book.active_booking || raise(NotBorrowed, "Book is not borrowed")

      booking.update!(returned_at: Time.current)
      booking
    end
  end
end
