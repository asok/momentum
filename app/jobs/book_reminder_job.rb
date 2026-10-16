class BookReminderJob < ApplicationJob
  def perform(booking_id, kind)
    booking = Booking.includes(:book, :user).find_by(id: booking_id)
    return unless booking && booking.returned_at.nil?

    message = BookReminderMailer.reminder(booking, kind)
    Rails.logger.info({ event: "book_reminder", booking_id: booking.id, to: message.to,
                        subject: message.subject, body: message.body.decoded }.to_json)
  end
end
