class CreateBook
  MAX_ATTEMPTS = 3

  def self.call(attributes:)
    new(attributes).call
  end

  def initialize(attributes)
    @attributes = attributes.except(:author)
    @author     = attributes[:author]
  end

  def call
    book = Book.new(@attributes)

    with_retry do
      book.author = Author.find_or_initialize_by(name: @author) if @author.present?
      book.save
    end

    book
  end

  private

  def with_retry
    attempts = 0

    begin
      attempts += 1

      yield
    rescue ActiveRecord::RecordNotUnique
      raise if attempts >= MAX_ATTEMPTS

      retry
    end
  end
end
