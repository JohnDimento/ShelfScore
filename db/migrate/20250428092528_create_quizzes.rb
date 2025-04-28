class CreateQuizzes < ActiveRecord::Migration[7.1]
  def change
    create_table :quizzes do |t|
      t.references :book, null: false, foreign_key: true
      t.string :title
      t.string :difficulty

      t.timestamps
    end
  end
end
