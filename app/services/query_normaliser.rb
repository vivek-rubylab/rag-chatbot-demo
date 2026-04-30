# Deterministic synonym expansion — no LLM involved.
# Applied to the raw user query before any search or entity extraction.
#
# Substitution rules are loaded from config/domain/synonyms.yml so that
# domain vocabulary can be updated without touching Ruby code.
#
# Order matters: rules are applied top-to-bottom. More specific patterns
# should appear before broader ones to avoid partial-match clobbering.
class QueryNormaliser
  CONFIG_PATH = Rails.root.join("config/domain/synonyms.yml")

  # Load once at boot and freeze — YAML parse on every request is unnecessary.
  SUBSTITUTIONS = YAML.load_file(CONFIG_PATH)
                      .fetch("substitutions")
                      .map { |s| [Regexp.new(s["pattern"], Regexp::IGNORECASE), s["replacement"]] }
                      .freeze

  def initialize(query)
    @query = query.to_s.strip
  end

  def call
    result = @query.dup
    SUBSTITUTIONS.each do |pattern, replacement|
      result = result.gsub(pattern, replacement)
    end
    result
  end
end
