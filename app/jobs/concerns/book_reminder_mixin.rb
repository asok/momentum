module BookReminderMixin
  extend ActiveSupport::Concern

  included do
    discard_on ActiveJob::DeserializationError
  end

  def perform(loan)
    return if loan.returned_at

    message = reminder_message(loan)

    log_message(loan, message)
    message.deliver_now
  end

  protected

  def log_message(loan, message)
    Rails.logger.info(
      {
        event:      "book_reminder",
        loan_id: loan.id,
        to:         message.to,
        subject:    message.subject,
        body:       message.body.decoded
      }.to_json
    )
  end
end
