require "rails_helper"

RSpec.describe KnowledgeRetriever do
  def retriever(query = "test", session_entities: nil)
    described_class.new(query, session_entities: session_entities)
  end

  describe "#passes_gate? (private)" do
    subject(:r) { retriever }

    it "passes when keyword score is positive" do
      expect(r.send(:passes_gate?, nil, 3, 0)).to be true
    end

    it "passes when entity boost is positive" do
      expect(r.send(:passes_gate?, nil, 0, 10)).to be true
    end

    it "passes when vector distance is below the threshold" do
      expect(r.send(:passes_gate?, 0.15, 0, 0)).to be true
    end

    it "does NOT pass at the exact threshold boundary (strict less-than)" do
      expect(r.send(:passes_gate?, described_class::VECTOR_DISTANCE_THRESHOLD, 0, 0)).to be false
    end

    it "fails when all signals are zero or nil" do
      expect(r.send(:passes_gate?, nil, 0, 0)).to be false
    end

    it "fails when vector distance exceeds threshold and no kw/entity signal" do
      expect(r.send(:passes_gate?, 0.35, 0, 0)).to be false
    end

    it "passes when vector distance is nil but keyword score is positive" do
      expect(r.send(:passes_gate?, nil, 1, 0)).to be true
    end
  end

  describe "#resolve_entities (private)" do
    let(:empty_session) { EntityExtractor::DIMENSIONS.index_with { [] } }

    it "returns current entities unchanged when there is no session context" do
      r = retriever("year 5 maths")
      current = { years: [:year_5], subjects: [:maths], formats: [], exam_boards: [] }
      expect(r.send(:resolve_entities, current)).to eq current
    end

    it "inherits a session dimension when the current query is silent on it" do
      session = { years: [:year_5], subjects: [], formats: [:online], exam_boards: [] }
      r = retriever("what about english", session_entities: session)
      current  = { years: [], subjects: [:english], formats: [], exam_boards: [] }
      resolved = r.send(:resolve_entities, current)

      expect(resolved[:years]).to(eq([:year_5]),   "should inherit year from session")
      expect(resolved[:subjects]).to(eq([:english]), "should keep current subject")
      expect(resolved[:formats]).to(eq([:online]),  "should inherit format from session")
    end

    it "uses the current query's value when it explicitly specifies a dimension" do
      session = { years: [:year_5], subjects: [], formats: [], exam_boards: [] }
      r = retriever("year 4 courses", session_entities: session)
      current  = { years: [:year_4], subjects: [], formats: [], exam_boards: [] }
      resolved = r.send(:resolve_entities, current)

      expect(resolved[:years]).to eq [:year_4]
    end

    it "handles an all-empty session gracefully" do
      r = retriever("year 6 online", session_entities: empty_session)
      current = { years: [:year_6], subjects: [], formats: [:online], exam_boards: [] }
      expect(r.send(:resolve_entities, current)).to eq current
    end
  end
end
