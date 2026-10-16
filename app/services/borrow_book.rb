class BorrowBook
  class AlreadyBorrowed < StandardError; end

  def self.call(book:, user:)
    booking = book.with_lock do
      raise AlreadyBorrowed, "Book is already borrowed" if book.bookings.where(returned_at: nil).exists?

      book.bookings.create!(user: user, borrowed_at: Time.current)
    end

    EarlyBookReminderJob.set(wait_until: booking.borrowed_at + 27.days).perform_later(booking)
    LaterBookReminderJob.set(wait_until: booking.borrowed_at + 30.days).perform_later(booking)
    booking
  end
end
