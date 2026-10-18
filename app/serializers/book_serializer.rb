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
    attributes(with_loans: true)
  end

  private

  def attributes(with_loans: false)
    data = { id: @book.id, serial_number: @book.serial_number, title: @book.title, author: @book.author,
             status: @book.active_loan ? "borrowed" : "available" }
    return data unless with_loans

    data.merge(loans: @book.loans.includes(:user).order(:borrowed_at, :id).map do |loan|
      LoanSerializer.new(loan).for_history
    end)
  end
end
