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
        print "You:"
        user_input = ask('')
        messages << user_message(user_input)
        print "AI:"
        response = ""
        llm.chat(messages: messages) do | chunk |
          content = chunk.dig('delta', 'content') rescue nil
          next unless content
          print content
          response += content
        end
        print "\n"
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
