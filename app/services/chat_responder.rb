# Orchestrates the full RAG pipeline for a single user message.
#
# Flow:
#   1. Accumulate entities from prior turns in this chat (session context)
#   2. Run KnowledgeRetriever with those session entities
#   3a. Nothing passes the gate → store the refusal message
#   3b. Entries pass → send to LLM with system prompt (or demo fallback if no key)
#
# The LLM only receives approved, gated, ranked entries — it does not decide
# whether it has the facts. That decision is made deterministically in step 2.
class ChatResponder
  REFUSAL = "I don't have enough information in my knowledge base to answer that. " \
            "Please contact us directly for help."

  # The LLM model to use for responses.
  # Override via LLM_MODEL env var — supports any model RubyLLM can reach.
  # Examples: gpt-4o-mini, claude-3-5-haiku-20241022, gemini-2.0-flash
  DEFAULT_MODEL = "gpt-4o-mini"

  def initialize(chat, user_message)
    @chat    = chat
    @message = user_message
    @content = user_message.content
  end

  # Pass a block to receive streaming chunks: call { |accumulated_text| ... }
  def call(&stream_callback)
    entries = KnowledgeRetriever.new(@content, session_entities: accumulated_entities).call

    return store_assistant_message(REFUSAL, {}) if entries.empty?

    entry_ids = entries.map(&:id)

    llm_configured? ? llm_response(entries, entry_ids, &stream_callback)
                    : demo_response(entries, entry_ids)
  end

  private

  # ── LLM response ──────────────────────────────────────────────────────────
  # Uses a fresh single-turn chat for every response.
  # Conversation history is intentionally excluded: session context is already
  # resolved at the retrieval layer (entity accumulation + resolve_entities),
  # so the LLM only needs the current question + gated knowledge entries.
  # Sending history causes the LLM to echo prior answers regardless of the
  # system prompt (context drift), which is worse than being stateless.

  def llm_response(entries, entry_ids, &stream_callback)
    context = entries.map { |e| "#{e.title}:\n#{e.body}" }.join("\n\n---\n\n")

    fresh_chat = RubyLLM.chat(model: llm_model)
    fresh_chat.with_instructions(system_prompt(context))

    full_response = ""

    if stream_callback
      batch = ""

      fresh_chat.ask(@content) do |chunk|
        delta = chunk.content.to_s
        next if delta.empty?

        full_response += delta
        batch         += delta

        # Yield batches of ~4 tokens so we don't flood the cable with single chars
        if batch.length >= 20
          stream_callback.call(batch)
          batch = ""
        end
      end

      # Flush any remaining text
      stream_callback.call(batch) if batch.present?
    else
      result         = fresh_chat.ask(@content)
      full_response  = result.content.to_s
    end

    store_assistant_message(full_response, { "knowledge_entry_ids" => entry_ids })
  end

  # Demo mode: no LLM key configured — surfaces the raw entries so the
  # pipeline is still visible and testable without any API credentials.
  def demo_response(entries, entry_ids)
    body    = entries.map { |e| "**#{e.title}**\n#{e.body}" }.join("\n\n")
    content = "*(Demo mode — no LLM key configured)*\n\nMatching knowledge base entries:\n\n#{body}"
    store_assistant_message(content, { "knowledge_entry_ids" => entry_ids })
  end

  def store_assistant_message(content, metadata)
    @chat.messages.create!(role: "assistant", content: content, metadata: metadata)
  end

  def system_prompt(context)
    # The user question is passed separately as the user message — NOT interpolated
    # here — so untrusted input cannot influence the system prompt boundary.
    <<~PROMPT
      You are a helpful support assistant for an 11+ tutoring service.

      Answer ONLY the user's question using ONLY the context provided below.
      Be concise and helpful. Do not make up information not present in the context.
      If the context does not contain enough information to answer the question,
      say exactly: "#{REFUSAL}"

      <context>
      #{context}
      </context>
    PROMPT
  end

  # ── Session entity accumulation ───────────────────────────────────────────
  # Scans all prior user messages in this chat and returns the LAST KNOWN VALUE
  # per dimension, so that follow-ups like "what about in-person?" inherit the
  # most recently stated year group — not every year group ever mentioned.
  #
  # Union-all (the previous approach) caused stale context: if a user asked
  # about Year 5, then Year 4, both would persist, confusing retrieval.
  # Last-known-value means a later explicit mention always wins.
  #
  # Example:
  #   turn 1: "Year 5 online maths"   → years: [:year_5], formats: [:online]
  #   turn 2: "what about Year 4?"    → years: [:year_4], formats: []
  #   accumulated after turn 2        → years: [:year_4], formats: [:online]

  def accumulated_entities
    prior_messages = @chat.messages
                          .where(role: "user")
                          .where.not(id: @message.id)
                          .order(:created_at)

    prior_messages.each_with_object(empty_entities) do |msg, acc|
      entities = EntityExtractor.new(QueryNormaliser.new(msg.content).call).call
      EntityExtractor::DIMENSIONS.each do |dim|
        acc[dim] = entities[dim] if entities[dim].any?
      end
    end
  end

  def empty_entities
    EntityExtractor::DIMENSIONS.each_with_object({}) { |dim, h| h[dim] = [] }
  end

  def llm_configured?
    ENV["OPENAI_API_KEY"].present?    ||
      ENV["ANTHROPIC_API_KEY"].present? ||
      ENV["GEMINI_API_KEY"].present?
  end

  def llm_model
    ENV.fetch("LLM_MODEL", DEFAULT_MODEL)
  end
end
