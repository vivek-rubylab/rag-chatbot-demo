# Generated from ruby_llm — creates the tables RubyLLM needs for
# acts_as_chat and acts_as_message. Kept in one migration for clarity.
class RubyLlmSchema < ActiveRecord::Migration[8.0]
  def change
    create_table :models do |t|
      t.string  :provider,    null: false
      t.string  :model_id,    null: false
      t.string  :name,        null: false
      t.string  :family
      t.jsonb   :capabilities,   default: []
      t.jsonb   :modalities,     default: {}
      t.jsonb   :pricing,        default: {}
      t.jsonb   :metadata,       default: {}
      t.integer :context_window
      t.integer :max_output_tokens
      t.date    :knowledge_cutoff
      t.datetime :model_created_at
      t.timestamps
    end
    add_index :models, %i[provider model_id], unique: true
    add_index :models, :provider
    add_index :models, :family
    add_index :models, :capabilities, using: :gin
    add_index :models, :modalities,   using: :gin

    create_table :chats do |t|
      t.bigint  :user_id
      t.string  :model_id
      t.timestamps
    end
    add_index :chats, :user_id

    create_table :tool_calls do |t|
      t.bigint :message_id, null: false
      t.string :tool_call_id, null: false
      t.string :name, null: false
      t.jsonb  :arguments, default: {}
      t.text   :thought_signature
      t.timestamps
    end
    add_index :tool_calls, :message_id
    add_index :tool_calls, :tool_call_id, unique: true
    add_index :tool_calls, :name

    create_table :messages do |t|
      t.bigint  :chat_id,     null: false
      t.string  :role,        null: false
      t.text    :content
      t.json    :content_raw
      t.bigint  :model_id
      t.bigint  :tool_call_id
      t.integer :input_tokens
      t.integer :output_tokens
      t.integer :cached_tokens
      t.integer :cache_creation_tokens
      t.text    :thinking_text
      t.text    :thinking_signature
      t.integer :thinking_tokens
      t.jsonb   :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :messages, :chat_id
    add_index :messages, :role
    add_index :messages, :model_id
    add_index :messages, :tool_call_id

    add_foreign_key :messages, :chats
    add_foreign_key :messages, :tool_calls
    add_foreign_key :tool_calls, :messages
  end
end
