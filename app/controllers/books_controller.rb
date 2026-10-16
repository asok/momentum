class BooksController < ApplicationController
  before_action :set_book, only: %i[show destroy borrow return]

  def index
    books = Book.includes(:author, :bookings).order(:id)
    render json: books.map { |book| BookSerializer.new(book).summary }
  end

  def show
    render json: BookSerializer.new(@book).with_history
  end

  def create
    book = Book.new(book_params.except(:author))
    book.author = Author.find_or_initialize_by(name: book_params[:author]) if book_params[:author].present?
    if book.save
      render json: BookSerializer.new(book).summary, status: :created
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

    render json: BookingSerializer.new(booking).for_borrow, status: :created
  rescue BorrowBook::AlreadyBorrowed => e
    render json: { error: e.message }, status: :conflict
  end

  def return
    booking = ReturnBook.call(book: @book)
    render json: BookingSerializer.new(booking).for_return
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
end
