require "ruby_rag"
require "thor"
require "dotenv"
require "langchain"

module RubyRag
  class Cli < Thor
    desc "chat", "Start chat"
    def chat
      Dotenv.load
      llm = llm(ENV['OPENAI_API_KEY'], 'gpt-3.5-turbo')

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

    desc "vector", "vector search"
    def vector(query)
      Dotenv.load
      llm = llm(ENV['OPENAI_API_KEY'], 'gpt-3.5-turbo')

      client = Langchain::Vectorsearch::Pinecone.new(
        environment: ENV['PINECONE_ENVIRONMENT'],
        api_key: ENV['PINECONE_API_KEY'],
        index_name: ENV['PINECONE_INDEX_NAME'],
        llm: llm
      )

      client.ask(question: query)
    end

    desc "assistant", "Assistant"
    def assistant
      Dotenv.load
      llm = llm(ENV['OPENAI_API_KEY'], 'gpt-4o')
      thread = Langchain::Thread.new
      assistant = Langchain::Assistant.new(
        llm: llm,
        thread: thread,
        tools: [
          Langchain::Tool::RubyCodeInterpreter.new
        ]
      )
      assistant.add_message content: "(1000 + 10) * (1000 - 10)を計算して"
      assistant.run(auto_tool_execution: true)
      assistant.messages.each do |message|
        puts "#{message.role}: #{message.content}"
      end
    end


    private

    def llm(api_key, model)
      Langchain::LLM::OpenAI.new(
        api_key: api_key,
        default_options: {
          chat_completion_model_name: model,
        }
      )
    end

    def user_message(message)
      { role: 'user', content: message }
    end

    def system_message(message)
      { role: 'system', content: message }
    end
  end
end
