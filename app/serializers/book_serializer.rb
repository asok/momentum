class BookSerializer
  def initialize(book)
    @book = book
  end

  def self.collection(books)
    books.map { |book| new(book).summary }
  end

  def summary
    attributes
  end

  def with_history
    attributes(with_bookings: true)
  end

  private

  def attributes(with_bookings: false)
    data = { id: @book.id, serial_number: @book.serial_number, title: @book.title, author: @book.author.name,
             status: @book.active_booking ? "borrowed" : "available" }
    return data unless with_bookings

    data.merge(bookings: @book.bookings.includes(:user).order(:borrowed_at, :id).map do |booking|
      BookingSerializer.new(booking).for_history
    end)
  end
end
