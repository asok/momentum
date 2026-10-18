# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Books API", type: :request do
  path "/api/public/v1/books" do
    get "List books" do
      tags "Books"
      produces "application/json"
      response "200", "books listed" do
        schema type: :array, items: {
          type:       :object,
          properties: {
            id:            { type: :integer },
            serial_number: { type: :string },
            title:         { type: :string },
            author:        { type: :string },
            status:        { type: :string, enum: %w[available borrowed] }
          },
          required:   %w[id serial_number title author status]
        }

        run_test!
      end
    end

    post "Create a book" do
      tags "Books"
      consumes "application/json"
      produces "application/json"
      parameter name: :book, in: :body, description: "Book details to add to the catalog.", schema: {
        type:       :object,
        properties: {
          book: {
            type:       :object,
            properties: {
              serial_number: { type: :string, example: "000001" },
              title:         { type: :string, example: "The Pragmatic Programmer" },
              author:        { type: :string, example: "David Thomas" }
            },
            required:   %w[serial_number title author]
          }
        },
        required:   ["book"]
      }

      response "201", "book created" do
        let(:book) do
          { book: { serial_number: "000001", title: "The Pragmatic Programmer", author: "David Thomas" } }
        end
        run_test!
      end

      response "422", "invalid book" do
        let(:book) { { book: { serial_number: "123", title: "Invalid", author: "Author" } } }
        run_test!
      end
    end
  end

  path "/api/public/v1/books/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "The unique ID of the book."

    get "Show a book and its loan history" do
      tags "Books"
      produces "application/json"
      response "200", "book found" do
        schema type:       :object,
               properties: {
            id:            { type: :integer },
            serial_number: { type: :string },
            title:         { type: :string },
            author:        { type: :string },
            status:        { type: :string, enum: %w[available borrowed] },
            loans:         { type: :array, items: { type: :object } }
          },
               required:   %w[id serial_number title author status loans]

        let(:id) { create(:book).id }
        run_test!
      end

      response "404", "book not found" do
        let(:id) { "missing" }
        run_test!
      end
    end

    delete "Delete a book" do
      tags "Books"
      response "204", "book deleted" do
        let(:id) { create(:book).id }
        run_test!
      end

      response "409", "book has an active loan" do
        let(:id) do
          book = create(:book)
          reader = create(:user)
          BorrowBook.call(book: book, user: reader)
          book.id
        end
        run_test!
      end
    end
  end

  path "/api/public/v1/books/{id}/borrow" do
    parameter name: :id, in: :path, type: :integer, description: "The unique ID of the book to borrow."

    post "Borrow a book" do
      tags "Loans"
      consumes "application/json"
      produces "application/json"
      parameter name: :card_number, in: :body, description: "The library card number of the reader borrowing the book.", schema: {
        type:       :object,
        properties: { card_number: { type: :string, example: "000123" } },
        required:   ["card_number"]
      }

      response "201", "book borrowed" do
        let(:id) { create(:book).id }
        let(:card_number) { { card_number: create(:user).card_number } }
        run_test!
      end

      response "404", "reader not found" do
        let(:id) { create(:book).id }
        let(:card_number) { { card_number: "999999" } }
        run_test!
      end
    end
  end

  path "/api/public/v1/books/{id}/return" do
    parameter name: :id, in: :path, type: :integer, description: "The unique ID of the book to return."

    post "Return a book" do
      tags "Loans"
      produces "application/json"
      response "200", "book returned" do
        let(:id) do
          book = create(:book)
          BorrowBook.call(book: book, user: create(:user))
          book.id
        end
        run_test!
      end

      response "409", "book is not borrowed" do
        let(:id) { create(:book).id }
        run_test!
      end
    end
  end
end
