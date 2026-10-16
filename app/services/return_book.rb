class ReturnBook
  class NotBorrowed < StandardError; end

  def self.call(book:)
    book.with_lock do
      booking = book.bookings.where(returned_at: nil).first
      raise NotBorrowed, "Book is not borrowed" unless booking

      booking.update!(returned_at: Time.current)
      booking
    end
  end
end
