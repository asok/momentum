class Booking < ApplicationRecord
  belongs_to :book
  belongs_to :user

  validates :borrowed_at, presence: true
  validate :return_not_before_borrow

  DUE_AT_DELAY = 30.days.freeze

  def due_at
    borrowed_at + DUE_AT_DELAY
  end

  private

  def return_not_before_borrow
    errors.add(:returned_at, "must not precede borrow date") if returned_at && borrowed_at && returned_at < borrowed_at
  end
end
