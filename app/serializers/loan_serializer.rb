class LoanSerializer
  def initialize(loan)
    @loan = loan
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
    data = { id: @loan.id, returned_at: @loan.returned_at }
    data[:reader] = UserSerializer.new(@loan.user).as_json if with_reader
    data[:borrowed_at] = @loan.borrowed_at if borrowed_at
    data[:due_at] = @loan.due_at if with_due_at

    if with_book
      data[:loan_id] = data.delete(:id)
      data[:book] = BookSerializer.new(@loan.book.reload).summary
    end

    data
  end
end
