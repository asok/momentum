class LaterBookReminderJob < ApplicationJob
  include BookReminderMixin

  private

  def reminder_message(loan)
    BookReminderMailer.late_reminder(loan)
  end
end
