class CreateQuizAttempts < ActiveRecord::Migration[7.1]
  def up
    create_table :quiz_attempts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :quiz, null: false, foreign_key: true
      t.decimal :score, precision: 5, scale: 2, null: false
      t.datetime :last_attempt_at, null: false

      t.timestamps
    end

    # Add a unique index using an expression for monthly attempts
    execute <<-SQL
      CREATE UNIQUE INDEX index_quiz_attempts_on_user_quiz_and_month
      ON quiz_attempts (user_id, quiz_id, DATE_TRUNC('month', last_attempt_at));
    SQL
  end

  def down
    drop_table :quiz_attempts
  end
end
