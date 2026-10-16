module BookReminderMixin
  extend ActiveSupport::Concern

  included do
    discard_on ActiveJob::DeserializationError
  end

  def perform(booking)
    return unless booking.returned_at.nil?

    message = reminder_message(booking)

    log_message(message)
  end

  protected

  def log_message(message)
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
