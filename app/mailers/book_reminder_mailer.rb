class BookReminderMailer < ActionMailer::Base
  default from: "library@example.com"

  def early_reminder(loan)
    send_reminder(loan, "Your library book is due in 3 days")
  end

  def late_reminder(loan)
    send_reminder(loan, "Your library book is due today")
  end

  private

  def send_reminder(loan, subject)
    mail(to: loan.user.email, subject: subject, body: reminder_body(loan))
  end

  def reminder_body(loan)
    <<~TEXT
      Hello #{loan.user.full_name},

      Please return #{loan.book.title} (#{loan.book.serial_number}) by #{loan.due_at.to_date}.
    TEXT
  end
end
