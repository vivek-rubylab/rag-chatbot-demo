# 11+ Tutor Chat — RAG Chatbot Demo

A working Rails application demonstrating a production-inspired RAG (Retrieval-Augmented Generation) chatbot architecture for bounded factual domains.

Built as the companion repo for the Medium article **[The LLM Is the Lead Singer. Don't Let It Run the Soundboard.](#)**

---

## What this demonstrates

Three real failures that shaped the architecture, and the code that fixes each one.

**Failure one — confidence ≠ correctness.**
The system does not ask the LLM to decide whether it has the facts. Everything upstream of the LLM exists to make that decision deterministically.

**Failure two — vocabulary mismatch.**
*"Do I need to sit a test to join?"* should find the admissions test entry even though "sit" and "join" don't appear in the knowledge base. Pure vector search fails here. The fix: hybrid retrieval (vector + keyword) and `retrieval_text` enrichment on each knowledge base entry.

**Failure three — silent context loss.**
*"What about in-person?"* is meaningless without the Year 5 context established earlier in the conversation. The retrieval layer — not the LLM — carries that context forward.

---

## Architecture

```
User query
    │
    ▼
① QueryNormaliser          — deterministic synonym expansion (YAML-configured)
    │
    ▼
② EntityExtractor          — rule-based entity detection: year, subject, format, board
    │
    ▼
③ resolve_entities         — fold in session context for follow-up queries
    │
    ▼
④ Hybrid retrieval         — vector search (pgvector) ∪ keyword scoring
    │
    ▼
⑤ Relevance gate           — passes if: vector distance < 0.22 (high-confidence semantic match)
    │                            OR kw_score > 0 (explicit term overlap)
    │                            OR entity_boost > 0 (recognised domain entity)
    │                          refuses if none of the above fire
    │
    ▼
⑥ Rank survivors           — combined score: vector rank + keyword + entity boost
    │
    ▼
⑦ LLM writes the response  — from approved context only
```

Steps ①–⑥ are deterministic and produce a full audit trail in the Rails log.
Step ⑦ is the only probabilistic step.

### Key files

| File | Purpose |
|------|---------|
| `app/services/query_normaliser.rb` | Synonym expansion — rules loaded from `config/domain/synonyms.yml` |
| `app/services/entity_extractor.rb` | Entity detection — patterns loaded from `config/domain/entities.yml` |
| `app/services/knowledge_retriever.rb` | Hybrid search, gate, ranking, session entity resolution |
| `app/services/chat_responder.rb` | Pipeline orchestration + session entity accumulation |
| `config/domain/synonyms.yml` | Domain vocabulary — edit this to adapt to your domain |
| `config/domain/entities.yml` | Entity patterns and keywords — edit this to adapt to your domain |
| `lib/tasks/kb.rake` | Sample knowledge base with `retrieval_text` enrichment — seed with `bin/rails kb:seed` |

---

## Stack

- **Ruby on Rails 8** — web framework
- **PostgreSQL + pgvector** — relational storage + vector similarity search
- **RubyLLM** — multi-provider LLM abstraction (OpenAI, Anthropic, Gemini)
- **Devise** — authentication
- **Solid Queue** — background jobs for embedding generation

---

## Getting started

### Prerequisites

- Ruby 3.2+
- PostgreSQL 14+ with the `pgvector` extension
- An API key for at least one LLM provider (OpenAI recommended — also used for embeddings)

### Setup

```bash
git clone https://github.com/your-username/rag-chatbot-demo.git
cd rag-chatbot-demo

# Install dependencies
bundle install

# Configure environment
cp .env.example .env
# Edit .env — add your API keys and database credentials

# Set up the database and seed the knowledge base
bin/rails db:create db:migrate
bin/rails kb:seed

# Start the server
bin/rails server
```

Open `http://localhost:3000`, sign up, and start chatting.

### Modes

| Configuration | Behaviour |
|--------------|-----------|
| No API keys | **Degraded mode** — keyword-only retrieval, no LLM responses, no embeddings. Useful for testing the pipeline locally. |
| `OPENAI_API_KEY` only | **Full mode** — hybrid search (vector + keyword) + LLM responses via OpenAI. Recommended starting point. |
| `OPENAI_API_KEY` + `ANTHROPIC_API_KEY` + `LLM_MODEL=claude-...` | Hybrid search (OpenAI embeddings) + Anthropic for chat responses. |
| `OPENAI_API_KEY` + `GEMINI_API_KEY` + `LLM_MODEL=gemini-...` | Hybrid search (OpenAI embeddings) + Gemini for chat responses. |

> **Note:** Vector search (hybrid mode) requires `OPENAI_API_KEY` regardless of which provider you use for LLM responses. Anthropic and Gemini keys alone enable LLM responses but not embeddings — the system falls back to keyword-only retrieval.

Embeddings are generated in the background after seeding. If you set `OPENAI_API_KEY` before running `bin/rails kb:seed`, they will be queued automatically. You can also trigger them manually:

```ruby
# Rails console
KnowledgeEntry.all.each(&:generate_embedding!)
```

---

## Adapting to your domain

The tutoring domain is the example — the architecture works for any bounded factual knowledge base.

**To swap in your own domain:**

1. Replace entries in `lib/tasks/kb.rake` with your own knowledge base content. Write `retrieval_text` carefully — it's the main lever for closing vocabulary gaps. Seed with `bin/rails kb:seed`.

2. Edit `config/domain/synonyms.yml` — add your abbreviations, product names, internal codes.

3. Edit `config/domain/entities.yml` — replace year groups, subjects, etc. with your own dimensions. Update `EntityExtractor::DIMENSIONS` and the dimension references in `KnowledgeRetriever` to match.

4. Update the system prompt in `ChatResponder#system_prompt` to describe your domain.

---

## Try these queries

After seeding, these queries demonstrate each failure mode:

```
"Do I need to sit a test to join?"
→ Failure two: vocabulary mismatch — "test" / "sit" don't overlap with "admissions"
  Watch synonyms.yml expand the query and retrieval_text bridge the vocabulary gap

"Tell me about Year 5 online courses"
  then: "What about in-person?"
→ Failure three: follow-up resolution
  Watch resolve_entities carry :year_5 forward before retrieval runs

"How many students are in a class?"
→ Gate passes: keyword + entity signal present

"Where do I pay?"
→ Gate blocks: no keyword or entity match — system refuses rather than guessing
```

Check the Rails log to see the full audit trail at each step.

---

## Deployment

The app runs on any platform that supports Rails and PostgreSQL. Ensure the `pgvector` extension is enabled on your database:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

Set all required ENV vars from `.env.example` in your hosting environment.
