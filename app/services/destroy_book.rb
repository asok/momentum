module DestroyBook
  extend self

  AlreadyBorrowed = Class.new(StandardError)

  def call(book:)
    book.with_lock do
      book.active_loan && raise(AlreadyBorrowed, "Return the book before deleting it")

      book.destroy!
    end
  end
end
