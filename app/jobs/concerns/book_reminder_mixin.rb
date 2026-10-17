module BookReminderMixin
  extend ActiveSupport::Concern

  included do
    discard_on ActiveJob::DeserializationError
  end

  def perform(booking)
    return if booking.returned_at

    message = reminder_message(booking)

    log_message(booking, message)
    message.deliver_now
  end

  protected

  def log_message(booking, message)
    Rails.logger.info(
      {
        event:      "book_reminder",
        booking_id: booking.id,
        to:         message.to,
        subject:    message.subject,
        body:       message.body.decoded
      }.to_json
    )
  end
end
