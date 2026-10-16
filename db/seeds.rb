# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

books = [
  ["100001", "Pride and Prejudice", "Jane Austen"],
  ["100002", "Jane Eyre", "Charlotte Brontë"],
  ["100003", "Wuthering Heights", "Emily Brontë"],
  ["100004", "Great Expectations", "Charles Dickens"],
  ["100005", "A Tale of Two Cities", "Charles Dickens"],
  ["100006", "Frankenstein", "Mary Shelley"],
  ["100007", "Dracula", "Bram Stoker"],
  ["100008", "The Picture of Dorian Gray", "Oscar Wilde"],
  ["100009", "Moby-Dick", "Herman Melville"],
  ["100010", "The Adventures of Huckleberry Finn", "Mark Twain"],
  ["100011", "Little Women", "Louisa May Alcott"],
  ["100012", "The Great Gatsby", "F. Scott Fitzgerald"],
  ["100013", "To Kill a Mockingbird", "Harper Lee"],
  ["100014", "1984", "George Orwell"],
  ["100015", "Animal Farm", "George Orwell"],
  ["100016", "Brave New World", "Aldous Huxley"],
  ["100017", "Fahrenheit 451", "Ray Bradbury"],
  ["100018", "The Hobbit", "J. R. R. Tolkien"],
  ["100019", "The Lord of the Rings", "J. R. R. Tolkien"],
  ["100020", "The Left Hand of Darkness", "Ursula K. Le Guin"]
]

books.each do |serial_number, title, author|
  Book.find_or_create_by!(serial_number: serial_number) do |book|
    book.title = title
    book.author = author
  end
end
