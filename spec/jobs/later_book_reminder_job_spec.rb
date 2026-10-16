require "rails_helper"

RSpec.describe LaterBookReminderJob, type: :job do
  include ActiveJob::TestHelper

  describe "when the booking has been deleted" do
    let(:booking) { create(:booking) }

    it "discards the reminder without raising an error" do
      described_class.perform_later(booking)
      booking.destroy!

      expect { perform_enqueued_jobs(only: described_class) }.not_to raise_error
    end
  end
end
