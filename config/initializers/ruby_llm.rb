RubyLLM.configure do |config|
  # Configure whichever providers you have API keys for.
  # At least one is required for LLM responses.
  # OpenAI is also required for embedding generation (vector search).
  #
  # See .env.example for the full list of ENV vars.

  config.openai_api_key    = ENV["OPENAI_API_KEY"]
  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
  config.gemini_api_key    = ENV["GEMINI_API_KEY"]
end
