require "rails_helper"

RSpec.describe EarlyBookReminderJob, type: :job do
  include ActiveJob::TestHelper

  describe "when the loan is open" do
    let(:loan) { create(:loan) }

    before { ActionMailer::Base.deliveries.clear }
    after { ActionMailer::Base.deliveries.clear }

    it "sends the early reminder to the reader" do
      described_class.perform_now(loan)

      expect(ActionMailer::Base.deliveries).to contain_exactly(
        have_attributes(
          to:      [loan.user.email],
          subject: "Your library book is due in 3 days",
          body:    have_attributes(decoded: "Hello #{loan.user.full_name},\n\nPlease return #{loan.book.title} (#{loan.book.serial_number}) by #{loan.due_at.to_date}.\n")
        )
      )
    end
  end

  describe "when the loan has been deleted" do
    let(:loan) { create(:loan) }

    it "discards the reminder without raising an error" do
      described_class.perform_later(loan)
      loan.destroy!

      expect { perform_enqueued_jobs(only: described_class) }.not_to raise_error
    end
  end
end
