class BookingSerializer
  def initialize(booking)
    @booking = booking
  end

  def for_history
    attributes
  end

  def for_borrow
    attributes(with_book: true).compact
  end

  def for_return
    attributes(with_book: true, with_due_at: false, borrowed_at: false, with_reader: false).compact
  end

  private

  def attributes(with_book: false, with_due_at: true, borrowed_at: true, with_reader: true)
    data = { id: @booking.id, returned_at: @booking.returned_at }
    data[:reader] = UserSerializer.new(@booking.user).as_json if with_reader
    data[:borrowed_at] = @booking.borrowed_at if borrowed_at
    data[:due_at] = @booking.due_at if with_due_at

    if with_book
      data[:booking_id] = data.delete(:id)
      data[:book] = BookSerializer.new(@booking.book.reload).summary
    end

    data
  end
end
