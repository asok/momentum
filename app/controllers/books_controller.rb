class BooksController < ApplicationController
  def index
    books = Book.includes(:author, :bookings).order(:id)

    render json: BookSerializer.collection(books)
  end

  def show
    render json: BookSerializer.new(resource).with_history
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
    resource.with_lock do
      if resource.bookings.where(returned_at: nil).exists?
        render_error("Return the book before deleting it", :conflict)
      else
        resource.destroy!

        head :no_content
      end
    end
  end

  def borrow
    user    = User.find_by(card_number: params.require(:card_number))
    booking = BorrowBook.call(book: resource, user: user)

    render json: BookingSerializer.new(booking).for_borrow, status: :created
  rescue BorrowBook::AlreadyBorrowed => e
    render_error(e.message, :conflict)
  rescue BorrowBook::UserNotFound => e
    render_error(e.message, :not_found)
  end

  def return
    booking = ReturnBook.call(book: resource)

    render json: BookingSerializer.new(booking).for_return
  rescue ReturnBook::NotBorrowed => e
    render_error(e.message, :conflict)
  end

  private

  def resource
    @book ||= Book.find(params.fetch(:id))
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
