class BooksController < ApplicationController
  before_action :set_book, only: %i[show destroy borrow return]

  def index
    books = Book.includes(:author, :bookings).order(:id)

    render json: BookSerializer.collection(books)
  end

  def show
    render json: BookSerializer.new(@book).with_history
  end

  def create
    book = CreateBook.call(attributes: book_params)

    if book.persisted?
      render json: BookSerializer.new(book).summary, status: :created
    else
      render_errors(book.errors.full_messages, :unprocessable_content)
    end
  end

  def destroy
    @book.with_lock do
      if @book.bookings.where(returned_at: nil).exists?
        render_error("Return the book before deleting it", :conflict)
      else
        @book.destroy!

        head :no_content
      end
    end
  end

  def borrow
    user = User.find_by(card_number: params.require(:card_number))
    return render_error("Reader not found", :not_found) unless user

    booking = BorrowBook.call(book: @book, user: user)

    render json: BookingSerializer.new(booking).for_borrow, status: :created
  rescue BorrowBook::AlreadyBorrowed => e
    render_error(e.message, :conflict)
  end

  def return
    booking = ReturnBook.call(book: @book)

    render json: BookingSerializer.new(booking).for_return
  rescue ReturnBook::NotBorrowed => e
    render_error(e.message, :conflict)
  end

  private

  def set_book
    @book = Book.find(params[:id])
  end

  def book_params
    @book_params ||= params.require(:book).permit(:serial_number, :title, :author)
  end

  def render_error(error, status)
    render json: { error: error }, status: status
  end

  def render_errors(errors, status)
    render json: { errors: errors }, status: status
  end
end
