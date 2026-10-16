class Booking < ApplicationRecord
  belongs_to :book
  belongs_to :user

  validates :borrowed_at, presence: true
  validate :return_not_before_borrow

  def due_at
    borrowed_at + 30.days
  end

  private

  def return_not_before_borrow
    errors.add(:returned_at, "must not precede borrow date") if returned_at && borrowed_at && returned_at < borrowed_at
  end
end
