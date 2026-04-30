require "rails_helper"

RSpec.describe ChatResponder do
  # These specs test accumulated_entities (entity carryover) and the refusal
  # path. No LLM calls are made — KnowledgeRetriever is stubbed where needed.

  let(:user) do
    User.create!(
      email:    "test_#{SecureRandom.hex(4)}@example.com",
      password: "password123"
    )
  end
  let(:chat) { Chat.create!(user: user) }

  def add_user_message(content)
    chat.messages.create!(role: "user", content: content)
  end

  def accumulated_for(msg)
    described_class.new(chat, msg).send(:accumulated_entities)
  end

  describe "#accumulated_entities — last-known-value carryover" do
    it "returns all-empty when there are no prior messages" do
      msg = add_user_message("what subjects do you cover")
      result = accumulated_for(msg)
      EntityExtractor::DIMENSIONS.each do |dim|
        expect(result[dim]).to be_empty, "expected #{dim} to be empty"
      end
    end

    it "carries the year group forward from a prior message" do
      add_user_message("year 5 courses")
      current = add_user_message("what about english")
      expect(accumulated_for(current)[:years]).to eq [:year_5]
    end

    it "uses the last-mentioned year when the year changed across turns" do
      add_user_message("year 5 maths")       # turn 1
      add_user_message("what about year 4")  # turn 2 — switches year
      current = add_user_message("what subjects are covered")

      # Should reflect year 4, not a union of [year_5, year_4]
      expect(accumulated_for(current)[:years]).to eq [:year_4]
    end

    it "carries the format forward from a prior message" do
      add_user_message("online year 5 maths")
      current = add_user_message("what about english")
      expect(accumulated_for(current)[:formats]).to eq [:online]
    end

    it "does not include the current message in the accumulated entities" do
      current = add_user_message("year 6 english")
      # No prior messages, so result must be empty even though current has entities
      expect(accumulated_for(current)[:years]).to be_empty
    end

    it "accumulated year from prior turn is overridden by an explicit year in the current query" do
      add_user_message("year 5 courses")
      current = add_user_message("year 6 maths")

      acc = accumulated_for(current)
      expect(acc[:years]).to eq [:year_5]  # accumulated = last from prior turns

      # resolve_entities (in KnowledgeRetriever) should then use year 6
      current_entities = EntityExtractor.new(QueryNormaliser.new("year 6 maths").call).call
      r = KnowledgeRetriever.new("year 6 maths", session_entities: acc)
      resolved = r.send(:resolve_entities, current_entities)
      expect(resolved[:years]).to eq [:year_6]
    end
  end

  describe "refusal path" do
    it "stores a refusal message when the retriever returns no entries" do
      current = add_user_message("zzz completely unrelated gibberish xyz")

      null_retriever = instance_double(KnowledgeRetriever, call: [])
      allow(KnowledgeRetriever).to receive(:new).and_return(null_retriever)

      result = described_class.new(chat, current).call
      expect(result.content).to eq described_class::REFUSAL
      expect(result.role).to    eq "assistant"
    end
  end
end
