class LaterBookReminderJob < ApplicationJob
  include BookReminderMixin

  private

  def reminder_message(booking)
    BookReminderMailer.late_reminder(booking)
  end
end
