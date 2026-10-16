class UserSerializer
  def initialize(user)
    @user = user
  end

  def as_json
    { card_number: @user.card_number, full_name: @user.full_name, email: @user.email }
  end
end
