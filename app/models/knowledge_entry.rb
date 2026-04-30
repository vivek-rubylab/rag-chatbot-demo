class KnowledgeEntry < ApplicationRecord
  has_neighbors :embedding

  validates :title, :body, presence: true

  scope :active, -> { where(active: true) }

  # Regenerate embedding whenever retrieval-relevant content changes.
  # Silently skips if no OpenAI key is configured (keyword-only mode).
  after_commit :enqueue_embedding, on: %i[create update], if: :embedding_needed?

  # Called by EmbeddingJob.
  # Prefers retrieval_text for embedding — it contains natural-language questions
  # that close the vocabulary gap between terse factual entries and user queries.
  def generate_embedding!
    text = retrieval_text.presence || "#{title}\n\n#{body}"
    update_column(:embedding, RubyLLM.embed(text).vectors)
  end

  private

  def embedding_needed?
    return false unless ENV["OPENAI_API_KEY"].present?

    previous_changes.key?("title")          ||
      previous_changes.key?("body")         ||
      previous_changes.key?("retrieval_text") ||
      embedding.nil?
  end

  def enqueue_embedding
    EmbeddingJob.perform_later(id)
  end
end
