class BooksController < ApplicationController
  before_action :set_book, only: %i[show destroy borrow return]

  def index
    books = Book.includes(:bookings).order(:id)
    render json: books.map { |book| book_data(book) }
  end

  def show
    render json: book_data(@book).merge(bookings: @book.bookings.includes(:user).order(:borrowed_at, :id).map do |booking|
      { id: booking.id, borrowed_at: booking.borrowed_at, due_at: booking.due_at,
        returned_at: booking.returned_at, reader: user_data(booking.user) }
    end)
  end

  def create
    book = Book.new(book_params)
    if book.save
      render json: book_data(book), status: :created
    else
      render json: { errors: book.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    @book.with_lock do
      if @book.bookings.where(returned_at: nil).exists?
        render json: { error: "Return the book before deleting it" }, status: :conflict
      else
        @book.destroy!
        head :no_content
      end
    end
  end

  def borrow
    user = User.find_by(card_number: params.require(:card_number))
    return render json: { error: "Reader not found" }, status: :not_found unless user

    booking = BorrowBook.call(book: @book, user: user)
    render json: { booking_id: booking.id, borrowed_at: booking.borrowed_at, due_at: booking.due_at,
                   book: book_data(@book.reload), reader: user_data(user) }, status: :created
  rescue BorrowBook::AlreadyBorrowed => e
    render json: { error: e.message }, status: :conflict
  end

  def return
    booking = ReturnBook.call(book: @book)
    render json: { booking_id: booking.id, returned_at: booking.returned_at, book: book_data(@book.reload) }
  rescue ReturnBook::NotBorrowed => e
    render json: { error: e.message }, status: :conflict
  end

  private

  def set_book
    @book = Book.find(params[:id])
  end

  def book_params
    params.require(:book).permit(:serial_number, :title, :author)
  end

  def book_data(book)
    { id: book.id, serial_number: book.serial_number, title: book.title, author: book.author,
      status: book.active_booking ? "borrowed" : "available" }
  end

  def user_data(user)
    { card_number: user.card_number, full_name: user.full_name, email: user.email }
  end
end
