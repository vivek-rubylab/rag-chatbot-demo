source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "~> 3.2"

gem "rails", "~> 8.0"
gem "pg",    "~> 1.5"       # PostgreSQL adapter
gem "puma",  "~> 8.0"       # Web server
gem "propshaft"             # Asset pipeline — serves JS/CSS from gems and app/assets
gem "bootsnap", require: false

# Auth
gem "devise", ">= 5.0.3"  # 4.9.x has CVE-2026-32700 (Confirmable token timing leak)

# LLM — supports OpenAI, Anthropic, Gemini and more via ENV config
gem "ruby_llm", "~> 1.3"

# Vector similarity search (pgvector)
gem "neighbor", "~> 0.4"

# Hotwire — real-time UI updates via Turbo Streams
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

# Background jobs (embedding generation + async AI responses)
gem "solid_queue"           # ships with Rails 8; swap for Sidekiq if preferred

# Database-backed ActionCable adapter — works across multiple processes (SolidQueue + Puma)
gem "solid_cable"

# Rate limiting — protects the message endpoint from abuse in public deployments
gem "rack-attack"

group :development, :test do
  gem "dotenv-rails"        # loads .env for local dev
  gem "debug"
  gem "rspec-rails",    "~> 7.0"
  gem "brakeman",       require: false  # static security analysis (CI)
  gem "bundler-audit",  require: false  # known CVE checks for gems (CI)
end

group :development do
  gem "web-console"
end
