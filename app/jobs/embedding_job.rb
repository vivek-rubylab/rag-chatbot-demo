# Generates and persists a vector embedding for a KnowledgeEntry.
# Triggered automatically after create/update (see KnowledgeEntry model).
# Only runs if OPENAI_API_KEY is set — silently no-ops otherwise.
class EmbeddingJob < ApplicationJob
  queue_as :default

  def perform(knowledge_entry_id)
    entry = KnowledgeEntry.find_by(id: knowledge_entry_id)
    return unless entry

    entry.generate_embedding!
    Rails.logger.info "[EmbeddingJob] Generated embedding for KnowledgeEntry ##{knowledge_entry_id}"
  rescue => e
    Rails.logger.error "[EmbeddingJob] Failed for ##{knowledge_entry_id}: #{e.message}"
    raise
  end
end
