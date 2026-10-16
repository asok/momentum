class Book < ApplicationRecord
  belongs_to :author
  has_many :bookings, dependent: :destroy

  validates :serial_number, presence: true, format: { with: /\A[0-9]{6}\z/ }, uniqueness: true
  validates :title, presence: true

  def active_booking
    if association(:bookings).loaded?
      bookings.find { |booking| booking.returned_at.nil? }
    else
      bookings.where(returned_at: nil).first
    end
  end
end
