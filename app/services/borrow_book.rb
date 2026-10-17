module BorrowBook
  extend self

  AlreadyBorrowed = Class.new(StandardError)
  UserNotFound    = Class.new(StandardError)

  REMINDERS = {
    EarlyBookReminderJob => Booking::DUE_AT_DELAY - 3.days,
    LaterBookReminderJob => Booking::DUE_AT_DELAY,
  }.freeze

  def call(book:, user:)
    assert_user(user)

    create_booking(book:, user:).tap do |booking|
      enqueue_reminders(booking)
    end
  end

  private

  def assert_user(user)
    raise UserNotFound, "Reader not found" unless user
  end

  def create_booking(book:, user:)
    book.with_lock do
      book.active_booking && raise(AlreadyBorrowed, "Book is already borrowed")

      book.bookings.create!(user: user, borrowed_at: Time.current)
    end
  end

  def enqueue_reminders(booking)
    REMINDERS.each_pair do |job_class, delay|
      job_class.set(wait_until: booking.borrowed_at + delay).perform_later(booking)
    end
  end
end
