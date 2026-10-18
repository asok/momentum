class User < ApplicationRecord
  has_many :loans, dependent: :restrict_with_error

  validates :card_number, presence: true, format: { with: /\A[0-9]{6}\z/ }, uniqueness: true
  validates :full_name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }
end
