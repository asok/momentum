module DestroyBook
  extend self

  AlreadyBorrowed = Class.new(StandardError)

  def call(book:)
    book.with_lock do
      raise(AlreadyBorrowed, "Return the book before deleting it") if book.active_loan

      book.destroy!
    end
  end
end
