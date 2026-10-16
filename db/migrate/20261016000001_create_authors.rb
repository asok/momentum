class CreateAuthors < ActiveRecord::Migration[8.1]
  def up
    create_table :authors do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :authors, :name, unique: true

    add_reference :books, :author, foreign_key: true
    execute <<~SQL
      INSERT INTO authors (name, created_at, updated_at)
      SELECT DISTINCT author, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM books
    SQL
    execute <<~SQL
      UPDATE books SET author_id = authors.id
      FROM authors WHERE books.author = authors.name
    SQL
    change_column_null :books, :author_id, false
    remove_column :books, :author
  end

  def down
    add_column :books, :author, :string
    execute <<~SQL
      UPDATE books SET author = authors.name
      FROM authors WHERE books.author_id = authors.id
    SQL
    change_column_null :books, :author, false
    remove_reference :books, :author, foreign_key: true
    drop_table :authors
  end
end
