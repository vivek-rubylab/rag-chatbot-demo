class CreateKnowledgeEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :knowledge_entries do |t|
      t.string  :title,          null: false
      t.text    :body,           null: false
      # retrieval_text: enriched with natural-language questions a user might ask.
      # Used for embedding generation — closes the vocabulary gap between terse
      # factual entries and natural-language queries (see Failure two in the blog).
      t.text    :retrieval_text
      t.string  :category
      t.boolean :active,         null: false, default: true
      # 1536 dimensions = OpenAI text-embedding-ada-002 / text-embedding-3-small.
      # Adjust if you switch embedding models.
      t.vector  :embedding,      limit: 1536
      t.timestamps
    end

    add_index :knowledge_entries, :active
  end
end
