class BookReminderJob < ApplicationJob
  discard_on ActiveJob::DeserializationError

  def perform(booking, kind)
    return unless booking.returned_at.nil?

    message = kind == "early" ? BookReminderMailer.early_reminder(booking) : BookReminderMailer.late_reminder(booking)
    Rails.logger.info({ event: "book_reminder", booking_id: booking.id, to: message.to,
                        subject: message.subject, body: message.body.decoded }.to_json)
  end
end
