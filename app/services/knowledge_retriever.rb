# Hybrid retrieval pipeline: vector search + keyword scoring + relevance gate.
#
# Pipeline:
#   1. Normalise query (QueryNormaliser)
#   2. Extract entities (EntityExtractor)
#   3. Resolve conversation context — fold in session entities for follow-ups
#   4. Retrieve candidates: vector search ∪ keyword search
#   5. Gate: pass if vector distance < 0.22 (high-confidence semantic match)
#            OR keyword score > 0 (explicit term overlap)
#            OR entity boost > 0 (recognised domain entity)
#   6. Score and rank survivors
#
# Operates in two modes:
#   - Full hybrid  (OPENAI_API_KEY set + embeddings exist): vector + keyword
#   - Keyword-only (no API key / no embeddings yet):        keyword only
#
# The keyword-only mode is intentional — the system works from day one,
# and embeddings are generated in the background as KnowledgeEntries are saved.
class KnowledgeRetriever
  VECTOR_LIMIT = 15   # how many vector neighbours to fetch before scoring
  FINAL_LIMIT  = 5    # how many entries to pass to the LLM

  STOP_WORDS = %w[
    the and for you your are can how what when where with our about do does is in on to
  ].freeze

  CONFIG_PATH = Rails.root.join("config/domain/entities.yml")
  KEYWORD_MAP = YAML.load_file(CONFIG_PATH).fetch("keywords").deep_symbolize_keys.freeze

  def initialize(query, limit: FINAL_LIMIT, session_entities: nil)
    @raw_query        = query.to_s.strip
    @limit            = limit
    @session_entities = session_entities
  end

  def call
    return [] if @raw_query.blank?

    normalised = QueryNormaliser.new(@raw_query).call
    entities   = EntityExtractor.new(normalised).call
    terms      = extract_terms(normalised)

    semantic_search_available? ? hybrid_search(normalised, terms, entities)
                                : keyword_only_search(terms)
  end

  private

  # ── Term extraction ────────────────────────────────────────────────────────

  def extract_terms(query)
    query.downcase
         .split(/[^a-z0-9]+/)
         .reject { |t| t.length < 3 || STOP_WORDS.include?(t) }
         .uniq
  end

  # ── Hybrid search ──────────────────────────────────────────────────────────

  def hybrid_search(normalised_query, terms, entities)
    # Resolve follow-up context BEFORE retrieval runs — not after.
    # This is the fix for "What about in-person?" style follow-ups.
    entities = resolve_entities(entities)

    Rails.logger.info "[KnowledgeRetriever] query=#{normalised_query.inspect} " \
                      "terms=#{terms.inspect} entities=#{entities.inspect}"

    vector_results    = vector_search(normalised_query)
    vector_ids        = vector_results.map(&:id)
    all_entries       = KnowledgeEntry.active.to_a
    kw_scores         = keyword_scores(all_entries, terms)

    Rails.logger.info "[KnowledgeRetriever] vector_hits=#{vector_ids.count} kw_hits=#{kw_scores.count}"

    candidate_ids = (vector_ids + kw_scores.keys).uniq
    candidates    = all_entries.select { |e| candidate_ids.include?(e.id) }

    vector_rank_map     = vector_ids.each_with_index.to_h { |id, i| [id, i + 1] }
    vector_distance_map = vector_results.each_with_object({}) do |entry, h|
      h[entry.id] = entry.neighbor_distance if entry.respond_to?(:neighbor_distance)
    end

    scored = candidates.filter_map do |entry|
      vrank    = vector_rank_map[entry.id]
      vdist    = vector_distance_map[entry.id]
      kw_score = kw_scores[entry.id] || 0
      e_boost  = entity_boost(entry, entities)
      gate     = passes_gate?(vdist, kw_score, e_boost)

      Rails.logger.info "[KnowledgeRetriever] candidate=#{entry.title.inspect} " \
                        "vrank=#{vrank.inspect} vdist=#{vdist&.round(3)} " \
                        "kw=#{kw_score} boost=#{e_boost} gate=#{gate}"

      next unless gate

      score = (vrank ? (VECTOR_LIMIT + 1 - vrank) : 0) + kw_score + e_boost
      [entry, score]
    end

    results = scored.sort_by { |_, score| -score }.first(@limit).map(&:first)

    # Safety net: if the gate eliminated everything, fall back to keyword-only
    # so a strict gate never causes a total miss on a valid query.
    if results.empty? && !terms.empty?
      Rails.logger.info "[KnowledgeRetriever] gate eliminated all candidates — falling back to keyword search"
      return keyword_only_search(terms)
    end

    results
  end

  def vector_search(query)
    KnowledgeEntry
      .active
      .where.not(embedding: nil)
      .nearest_neighbors(:embedding, RubyLLM.embed(query).vectors, distance: "cosine")
      .limit(VECTOR_LIMIT)
      .to_a
  end

  # ── Relevance gate ─────────────────────────────────────────────────────────
  # Three ways to pass:
  #   1. High-confidence vector match (cosine distance < 0.22) — semantically
  #      very close even if vocabulary doesn't overlap (handles "Y5", slang, etc.)
  #   2. Non-zero keyword score — explicit term overlap
  #   3. Non-zero entity boost — recognised domain entity match
  #
  # Vector proximity alone is NOT sufficient at higher distances — pgvector always
  # returns the nearest match regardless of relevance, which would cause the LLM
  # to answer out-of-scope queries with whatever is least-bad in the knowledge base.
  VECTOR_DISTANCE_THRESHOLD = 0.22

  def passes_gate?(vector_distance, kw_score, e_boost)
    (vector_distance && vector_distance < VECTOR_DISTANCE_THRESHOLD) ||
      kw_score > 0 ||
      e_boost > 0
  end

  # ── Session entity resolution ──────────────────────────────────────────────
  # Merges current-query entities with accumulated session entities so that
  # underspecified follow-ups ("what about English?", "what about in-person?")
  # carry forward context from prior turns at the retrieval layer — not the LLM.
  #
  # Override-with-fallback rule per dimension:
  #   current query has values → use them (user is being explicit)
  #   current query is silent  → inherit from session
  #
  # Example:
  #   session  = { years: [:year_5], formats: [:online], subjects: [], exam_boards: [] }
  #   current  = { years: [],        formats: [],        subjects: [:english], exam_boards: [] }
  #   resolved = { years: [:year_5], formats: [:online], subjects: [:english], exam_boards: [] }
  def resolve_entities(current)
    return current if @session_entities.nil?

    resolved = EntityExtractor::DIMENSIONS.each_with_object({}) do |dim, h|
      h[dim] = current[dim].any? ? current[dim] : (@session_entities[dim] || [])
    end

    if resolved != current
      Rails.logger.info "[KnowledgeRetriever] session_entities=#{@session_entities.inspect} " \
                        "resolved=#{resolved.inspect}"
    end

    resolved
  end

  # ── Entity boost ───────────────────────────────────────────────────────────

  def entity_boost(entry, entities)
    return 0 if entities.values.all?(&:empty?)

    text  = [entry.retrieval_text, entry.title, entry.body].compact.join(" ").downcase
    boost = 0
    boost += 20 if matches_any?(text, entities[:years],       KEYWORD_MAP[:years])
    boost += 10 if matches_any?(text, entities[:subjects],    KEYWORD_MAP[:subjects])
    boost += 10 if matches_any?(text, entities[:formats],     KEYWORD_MAP[:formats])
    boost += 10 if matches_any?(text, entities[:exam_boards], KEYWORD_MAP[:exam_boards])
    boost
  end

  def matches_any?(text, entity_set, keyword_map)
    entity_set.any? { |entity| keyword_map[entity]&.any? { |kw| text.include?(kw) } }
  end

  # ── Keyword scoring ────────────────────────────────────────────────────────

  def keyword_scores(entries, terms)
    return {} if terms.empty?

    entries.each_with_object({}) do |entry, scores|
      score = keyword_score(entry, terms)
      scores[entry.id] = score if score > 0
    end
  end

  def keyword_score(entry, terms)
    text = [entry.retrieval_text, entry.title, entry.body].compact.join(" ").downcase
    terms.sum { |term| text.scan(term).count }
  end

  # ── Keyword-only fallback ─────────────────────────────────────────────────

  def keyword_only_search(terms)
    return [] if terms.empty?

    entries = KnowledgeEntry.active.to_a
    scores  = keyword_scores(entries, terms)
    return [] if scores.empty?

    entries.select { |e| scores.key?(e.id) }
           .sort_by { |e| [-scores[e.id], -e.updated_at.to_i] }
           .first(@limit)
  end

  def semantic_search_available?
    ENV["OPENAI_API_KEY"].present? &&
      KnowledgeEntry.active.where.not(embedding: nil).exists?
  end
end
