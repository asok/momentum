class CreateBook

  def self.call(attributes:)
    new(attributes).call
  end

  def initialize(attributes)
    @attributes = attributes
  end

  def call
    book = Book.new(@attributes)

    book.save
    book
  end
end
