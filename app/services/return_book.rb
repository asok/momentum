module ReturnBook
  extend self

  NotBorrowed = Class.new(StandardError)

  def call(book:)
    book.with_lock do
      loan = book.active_loan || raise(NotBorrowed, "Book is not borrowed")

      loan.update!(returned_at: Time.current)
      loan
    end
  end
end
