class EarlyBookReminderJob < ApplicationJob
  include BookReminderMixin

  private

  def reminder_message(booking)
    BookReminderMailer.early_reminder(booking)
  end
end
