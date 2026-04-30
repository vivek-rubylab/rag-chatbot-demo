# Extracts domain entities from a pre-normalised query (run QueryNormaliser first).
# Returns a hash of sets — handles compound questions naturally.
#
# Example:
#   "Do Year 4 and Year 5 online courses cover VR and NVR for GL?"
#   => { years: [:year_4, :year_5], subjects: [:vr, :nvr],
#         formats: [:online], exam_boards: [:gl] }
#
# Entity patterns are loaded from config/domain/entities.yml.
# To add a new dimension, add it under `patterns:` in the YAML and update
# the `DIMENSIONS` list and the `call` method below.
class EntityExtractor
  CONFIG_PATH = Rails.root.join("config/domain/entities.yml")

  DIMENSIONS = %i[years subjects formats exam_boards].freeze

  # Load patterns once at boot and compile to regex.
  PATTERNS = begin
    raw = YAML.load_file(CONFIG_PATH).fetch("patterns")
    DIMENSIONS.each_with_object({}) do |dim, h|
      h[dim] = raw[dim.to_s].transform_keys(&:to_sym)
                             .transform_values { |p| Regexp.new(p, Regexp::IGNORECASE) }
    end
  end.freeze

  def initialize(normalised_query)
    @query = normalised_query.to_s
  end

  def call
    DIMENSIONS.each_with_object({}) do |dim, result|
      result[dim] = extract(PATTERNS[dim])
    end
  end

  private

  def extract(patterns)
    patterns.each_with_object([]) do |(key, pattern), matches|
      matches << key if @query.match?(pattern)
    end
  end
end
