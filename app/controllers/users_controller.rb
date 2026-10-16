class UsersController < ApplicationController
  def create
    user = User.new(params.require(:user).permit(:card_number, :full_name, :email))
    if user.save
      render json: { id: user.id, card_number: user.card_number, full_name: user.full_name, email: user.email }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_content
    end
  end
end
