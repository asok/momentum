class BookReminderMailer < ActionMailer::Base
  default from: "library@example.com"

  def reminder(booking, kind)
    due_date = booking.due_at.to_date
    subject = kind == "early" ? "Your library book is due in 3 days" : "Your library book is due today"
    mail(to: booking.user.email, subject: subject, body: "Hello #{booking.user.full_name},\n\nPlease return #{booking.book.title} (#{booking.book.serial_number}) by #{due_date}.\n")
  end
end
