require "rails_helper"

RSpec.describe CreateBook do
  describe ".call" do
    it "makes no more than three attempts after unique constraint errors" do
      save_attempts = 0
      allow_any_instance_of(Book).to receive(:save) do
        save_attempts += 1
        Author.create!(name: "A Writer") if save_attempts == 1
        raise ActiveRecord::RecordNotUnique
      end

      expect {
        described_class.call(attributes: { serial_number: "000001", title: "A Book", author: "A Writer" })
      }.to raise_error(ActiveRecord::RecordNotUnique)
      expect(save_attempts).to eq(3)
    end
  end
end
