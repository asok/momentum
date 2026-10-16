class BorrowBook
  class AlreadyBorrowed < StandardError; end

  def self.call(book:, user:)
    booking = book.with_lock do
      raise AlreadyBorrowed, "Book is already borrowed" if book.bookings.where(returned_at: nil).exists?

      book.bookings.create!(user: user, borrowed_at: Time.current)
    end

    [ 27.days, 30.days ].each do |offset|
      BookReminderJob.set(wait_until: booking.borrowed_at + offset).perform_later(booking, offset == 27.days ? "early" : "due")
    end
    booking
  end
end
