# app/services/quiz_generator.rb
class QuizGenerator
  def initialize(book)
    @book   = book
    @client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
  end

  # returns a Quiz or raises if no questions
  # if quiz is provided, adds questions to that quiz instead of creating a new one
  def generate_quiz!(quiz = nil)
    questions = fetch_questions!
    raise "No questions returned from OpenAI" if questions.empty?

    quiz ||= @book.quizzes.create!(title: "Quiz for #{@book.title}")
    questions.each do |q|
      quiz.questions.create!(
        content:        q.fetch("content"),
        options:        q.fetch("options"),
        correct_answer: q.fetch("correct_answer")
      )
    end
    quiz
  end

  private

  def fetch_questions!
    prompt = <<~PROMPT
      You are a literature expert. Generate a quiz about this book.
      Return ONLY raw JSON - no markdown, no code blocks, no explanation.
      The response must be a JSON array of 10 objects, each with:
      - "content": the question text
      - "options": an array of 4 answer strings
      - "correct_answer": one of "A","B","C","D"

      Book title: #{@book.title}
      Author: #{@book.author}
      #{ @book.description.present? ? "Description: #{@book.description}" : "" }
      #{ @book.published_year.present? ? "Published: #{@book.published_year}" : "" }
    PROMPT

    messages = [
      { role: "system", content: "You are a JSON-only API. Never use markdown formatting. Never explain. Only output valid JSON." },
      { role: "user",   content: prompt }
    ]

    resp = @client.chat(
      parameters: {
        model:       "gpt-3.5-turbo",
        messages:    messages,
        temperature: 0.0,
        max_tokens: 1500
      }
    )

    body = resp.dig("choices", 0, "message", "content") || ""

    # Remove any markdown code block markers if present
    body = body.gsub(/```(?:json)?\n?/, '').strip

    data = JSON.parse(body)

    unless data.is_a?(Array)
      Rails.logger.error("QuizGenerator: expected Array but got #{data.class}. Response was:\n#{body}")
      return []
    end

    data
  rescue JSON::ParserError => e
    Rails.logger.error("QuizGenerator JSON parse error: #{e.message}")
    Rails.logger.error("Raw response: #{body}")
    []
  rescue OpenAI::Error => e
    Rails.logger.error("OpenAI API error: #{e.message}")
    []
  end
end
