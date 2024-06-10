require "ruby_rag"
require "thor"
require "dotenv"
require "langchain"

module RubyRag
  class Cli < Thor
    desc "chat", "Start chat"
    def chat
      Dotenv.load
      llm = Langchain::LLM::OpenAI.new(
        api_key: ENV['OPENAI_API_KEY'],
        default_options: {
          chat_completion_model_name: 'gpt-3.5-turbo',
        }
      )

      messages = []

      loop do
        user_input = ask('You: ')
        messages << user_message(user_input)
        response = llm.chat(messages: messages).completion
        puts "AI: #{response}"
        messages << system_message(response)
      end
    end

    private

    def user_message(message)
      { role: 'user', content: message }
    end

    def system_message(message)
      { role: 'system', content: message }
    end
  end
end
