module CreateBook
  extend self

  def call(attributes)
    book = Book.new(attributes)

    book.save
    book
  end
end
