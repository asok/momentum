class Book < ApplicationRecord
  has_many :loans, dependent: :destroy

  validates :serial_number, presence: true, format: { with: /\A[0-9]{6}\z/ }, uniqueness: true
  validates :title, presence: true
  validates :author, presence: true

  def active_loan
    if association(:loans).loaded?
      loans.detect { |loan| loan.returned_at.nil? }
    else
      loans.where(returned_at: nil).first
    end
  end
end
