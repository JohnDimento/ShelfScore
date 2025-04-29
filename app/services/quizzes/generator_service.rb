# frozen_string_literal: true

module Quizzes
  class GeneratorService < Base::Service
    QUESTION_COUNT = 10
    MODEL = "gpt-3.5-turbo"
    MAX_TOKENS = 1500

    def initialize(book)
      @book = book
      @client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
    end

    def generate_quiz
      result = call
      result[:success?] ? result[:quiz] : nil
    end

    def generate_quiz!
      result = call
      raise "Failed to generate quiz: #{result[:error]}" unless result[:success?]
      result[:quiz]
    end

    def call(quiz = nil)
      questions = fetch_questions
      return failure("No questions returned from OpenAI") if questions.empty?

      quiz ||= @book.quizzes.build(title: "Quiz for #{@book.title}")

      ActiveRecord::Base.transaction do
        quiz.save!
        create_questions!(quiz, questions)
      end

      success(quiz: quiz)
    rescue ActiveRecord::RecordInvalid => e
      failure("Failed to save quiz: #{e.message}")
    end

    private

    def create_questions!(quiz, questions)
      questions.each do |q|
        quiz.questions.create!(
          content: q.fetch("content"),
          options: q.fetch("options"),
          correct_answer: q.fetch("correct_answer")
        )
      end
    end

    def fetch_questions
      response = @client.chat(
        parameters: {
          model: MODEL,
          messages: chat_messages,
          temperature: 0.0,
          max_tokens: MAX_TOKENS
        }
      )

      parse_response(response)
    rescue OpenAI::Error => e
      Rails.logger.error("OpenAI API error: #{e.message}")
      []
    end

    def chat_messages
      [
        {
          role: "system",
          content: "You are a JSON-only API. Never use markdown formatting. Never explain. Only output valid JSON."
        },
        {
          role: "user",
          content: generate_prompt
        }
      ]
    end

    def generate_prompt
      <<~PROMPT
        You are a literature expert. Generate a quiz about this book.
        Return ONLY raw JSON - no markdown, no code blocks, no explanation.
        The response must be a JSON array of #{QUESTION_COUNT} objects, each with:
        - "content": the question text
        - "options": an array of 4 answer strings
        - "correct_answer": one of "A","B","C","D"

        Book title: #{@book.title}
        Author: #{@book.author}
        #{@book.description.present? ? "Description: #{@book.description}" : ""}
        #{@book.published_year.present? ? "Published: #{@book.published_year}" : ""}
      PROMPT
    end

    def parse_response(response)
      body = response.dig("choices", 0, "message", "content") || ""
      body = body.gsub(/```(?:json)?\n?/, '').strip

      data = JSON.parse(body)
      return [] unless data.is_a?(Array)

      data
    rescue JSON::ParserError => e
      Rails.logger.error("QuizGenerator JSON parse error: #{e.message}")
      Rails.logger.error("Raw response: #{body}")
      []
    end
  end
end
