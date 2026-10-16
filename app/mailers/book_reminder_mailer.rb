class BookReminderMailer < ActionMailer::Base
  default from: "library@example.com"

  def early_reminder(booking)
    send_reminder(booking, "Your library book is due in 3 days")
  end

  def late_reminder(booking)
    send_reminder(booking, "Your library book is due today")
  end

  private

  def send_reminder(booking, subject)
    mail(to: booking.user.email, subject: subject, body: reminder_body(booking))
  end

  def reminder_body(booking)
    <<~TEXT
      Hello #{booking.user.full_name},

      Please return #{booking.book.title} (#{booking.book.serial_number}) by #{booking.due_at.to_date}.
    TEXT
  end
end
