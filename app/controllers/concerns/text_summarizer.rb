module TextSummarizer
  extend ActiveSupport::Concern
  include Groq::Helpers

  def summarize_text(text)
    prompt = "Retrieve the recipe from this text:\n\n#{text}"

    client = Groq::Client.new
    response = client.chat([
        S(ENV["LLM_SYSTEM_PROMPT"]),
        U(prompt)
      ]
    )

    Rails.logger.debug("LLM Response: #{response}")

    response["content"]
  rescue StandardError => e
    Rails.logger.error("Error summarizing text with Groq: #{e.message}")
    @error = "Error: Unable to summarize the text. Providing raw text instead."
    text
  end
end
