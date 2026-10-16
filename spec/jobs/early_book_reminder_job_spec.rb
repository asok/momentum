require "rails_helper"

RSpec.describe EarlyBookReminderJob, type: :job do
  include ActiveJob::TestHelper

  describe "when the booking is open" do
    let(:booking) { create(:booking) }

    before { ActionMailer::Base.deliveries.clear }
    after { ActionMailer::Base.deliveries.clear }

    it "sends the early reminder to the reader" do
      described_class.perform_now(booking)

      expect(ActionMailer::Base.deliveries).to contain_exactly(
        have_attributes(
          to:      [booking.user.email],
          subject: "Your library book is due in 3 days",
          body:    have_attributes(decoded: "Hello #{booking.user.full_name},\n\nPlease return #{booking.book.title} (#{booking.book.serial_number}) by #{booking.due_at.to_date}.\n")
        )
      )
    end
  end

  describe "when the booking has been deleted" do
    let(:booking) { create(:booking) }

    it "discards the reminder without raising an error" do
      described_class.perform_later(booking)
      booking.destroy!

      expect { perform_enqueued_jobs(only: described_class) }.not_to raise_error
    end
  end
end
