# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_05_03_212557) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "books", force: :cascade do |t|
    t.string "title"
    t.string "author"
    t.string "series"
    t.text "description"
    t.integer "published_year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "google_books_id"
    t.string "isbn_13"
    t.string "isbn_10"
    t.integer "page_count"
    t.string "categories", default: [], array: true
    t.decimal "average_rating", precision: 3, scale: 2
    t.integer "ratings_count"
    t.string "thumbnail_url"
    t.string "preview_link"
    t.bigint "user_id", null: false
    t.index ["google_books_id"], name: "index_books_on_google_books_id", unique: true
    t.index ["isbn_10"], name: "index_books_on_isbn_10"
    t.index ["isbn_13"], name: "index_books_on_isbn_13"
    t.index ["user_id"], name: "index_books_on_user_id"
  end

  create_table "questions", force: :cascade do |t|
    t.text "content"
    t.jsonb "options"
    t.string "correct_answer"
    t.bigint "quiz_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_id"], name: "index_questions_on_quiz_id"
  end

  create_table "quiz_attempts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "quiz_id", null: false
    t.decimal "score", precision: 5, scale: 2, null: false
    t.datetime "last_attempt_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "user_id, quiz_id, date_trunc('month'::text, last_attempt_at)", name: "index_quiz_attempts_on_user_quiz_and_month", unique: true
    t.index ["quiz_id"], name: "index_quiz_attempts_on_quiz_id"
    t.index ["user_id"], name: "index_quiz_attempts_on_user_id"
  end

  create_table "quizzes", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.string "title"
    t.string "difficulty"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_quizzes_on_book_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "points", default: 0
    t.string "display_name"
    t.text "bio"
    t.string "avatar_url"
    t.integer "reading_goal"
    t.string "theme_preference"
    t.jsonb "privacy_settings"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "books", "users"
  add_foreign_key "questions", "quizzes"
  add_foreign_key "quiz_attempts", "quizzes"
  add_foreign_key "quiz_attempts", "users"
  add_foreign_key "quizzes", "books"
end
