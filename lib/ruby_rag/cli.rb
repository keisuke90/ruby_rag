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

    desc "ask", "RAG"
    def ask(query)
      Dotenv.load
      llm = llm(ENV['OPENAI_API_KEY'], 'gpt-3.5-turbo')
      client = pinecone(ENV['PINECONE_ENVIRONMENT'],
                        ENV['PINECONE_API_KEY'],
                        ENV['PINECONE_INDEX_NAME'],
                        llm)

      res = client.ask(question: query)
      puts res.raw_response.dig("choices", 0, "message", "content")
    end

    desc "similarity", "Similarity"
    def vector(query, k = 5)
      Dotenv.load
      llm = llm(ENV['OPENAI_API_KEY'], 'gpt-3.5-turbo')
      client = pinecone(ENV['PINECONE_ENVIRONMENT'],
                        ENV['PINECONE_API_KEY'],
                        ENV['PINECONE_INDEX_NAME'],
                        llm)

      res = client.similarity_search(query: query, k: k)
      res = res.map {|item| item["metadata"]["content"] }
      res.each_with_index do |content, idx|
        puts "No.#{idx + 1}================"
        puts content
      end
    end

    desc "assistant", "Assistant"
    def assistant(content)
      Dotenv.load
      llm = llm(ENV['OPENAI_API_KEY'], 'gpt-4o')
      thread = Langchain::Thread.new
      assistant = Langchain::Assistant.new(
        llm: llm,
        thread: thread,
        tools: [
          Langchain::Tool::RubyCodeInterpreter.new,
          Langchain::Tool::FileSystem.new
        ]
      )
      assistant.add_message(content: content)
      assistant.run(auto_tool_execution: true)
      puts assistant.messages
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

    def pinecone(environment, api_key, index_name, llm)
      Langchain::Vectorsearch::Pinecone.new(
        environment: environment,
        api_key: api_key,
        index_name: index_name,
        llm: llm
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
