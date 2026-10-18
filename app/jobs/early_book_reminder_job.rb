class EarlyBookReminderJob < ApplicationJob
  include BookReminderMixin

  private

  def reminder_message(loan)
    BookReminderMailer.early_reminder(loan)
  end
end
