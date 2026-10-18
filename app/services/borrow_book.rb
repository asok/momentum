module BorrowBook
  extend self

  AlreadyBorrowed        = Class.new(StandardError)
  UserNotFound           = Class.new(StandardError)
  ReminderEnqueueFailed  = Class.new(StandardError)

  REMINDERS = {
    EarlyBookReminderJob => Loan::DUE_AT_DELAY - 3.days,
    LaterBookReminderJob => Loan::DUE_AT_DELAY,
  }.freeze

  def call(book:, user:)
    assert_user(user)

    # SolidQueue is using the same db connection so enqueueing is atomic.
    # Also the nice side effect is that there's no need for
    # "transactional mailbox".
    book.transaction do
      loan = create_loan(book:, user:)

      enqueue_reminders(loan)

      loan
    end
  end

  private

  def assert_user(user)
    raise UserNotFound, "Reader not found" unless user
  end

  def create_loan(book:, user:)
    book.with_lock do
      book.active_loan && raise(AlreadyBorrowed, "Book is already borrowed")

      book.loans.create!(user: user, borrowed_at: Time.current)
    end
  end

  def enqueue_reminders(loan)
    REMINDERS.each_pair do |job_class, delay|
      enqueue(loan:, job_class:, delay:) ||
        raise(ReminderEnqueueFailed, "Could not enqueue #{job_class.name}")
    end
  end

  def enqueue(loan:, job_class:, delay:)
    job_class.set(wait_until: loan.borrowed_at + delay).perform_later(loan)
  end
end
