require "rails_helper"

RSpec.describe EntityExtractor do
  def extract(query)
    described_class.new(query).call
  end

  # Normalise then extract — mirrors the real pipeline path
  def pipeline(raw)
    extract(QueryNormaliser.new(raw).call)
  end

  describe "year group detection" do
    it "extracts year_5 from a normalised query" do
      expect(extract("year 5 courses")[:years]).to eq [:year_5]
    end

    it "extracts year_6 via pipeline from Y6 shorthand" do
      expect(pipeline("Y6")[:years]).to eq [:year_6]
    end

    it "extracts year_4 via pipeline from yr4 shorthand" do
      expect(pipeline("yr4")[:years]).to eq [:year_4]
    end

    it "extracts multiple year groups from a compound query" do
      years = extract("year 4 and year 5 courses")[:years]
      expect(years).to include(:year_4, :year_5)
    end

    it "returns no years when none are present" do
      expect(extract("what subjects do you cover")[:years]).to be_empty
    end
  end

  describe "subject detection" do
    it "extracts english" do
      expect(extract("english courses")[:subjects]).to eq [:english]
    end

    it "extracts maths" do
      expect(extract("maths tuition")[:subjects]).to eq [:maths]
    end

    it "extracts vr from 'verbal reasoning'" do
      expect(extract("verbal reasoning")[:subjects]).to eq [:vr]
    end

    it "extracts nvr from 'non-verbal reasoning'" do
      expect(extract("non-verbal reasoning")[:subjects]).to eq [:nvr]
    end

    it "extracts nvr via pipeline from 'nvr' shorthand" do
      expect(pipeline("nvr")[:subjects]).to eq [:nvr]
    end

    it "extracts vr via pipeline from 'vr' shorthand" do
      expect(pipeline("vr")[:subjects]).to eq [:vr]
    end
  end

  describe "format detection" do
    it "extracts online" do
      expect(extract("online classes")[:formats]).to eq [:online]
    end

    it "extracts in_person from 'in-person'" do
      expect(extract("in-person tuition")[:formats]).to eq [:in_person]
    end

    it "extracts in_person via pipeline from 'face-to-face'" do
      expect(pipeline("face-to-face")[:formats]).to eq [:in_person]
    end

    it "extracts online via pipeline from 'remote'" do
      expect(pipeline("remote")[:formats]).to eq [:online]
    end
  end

  describe "exam board detection" do
    it "extracts gl" do
      expect(extract("GL Assessment paper")[:exam_boards]).to eq [:gl]
    end

    it "extracts cem" do
      expect(extract("CEM format")[:exam_boards]).to eq [:cem]
    end
  end

  describe "compound query" do
    it "extracts multiple dimensions at once" do
      result = pipeline("Y5 online english")
      expect(result[:years]).to    eq [:year_5]
      expect(result[:formats]).to  eq [:online]
      expect(result[:subjects]).to eq [:english]
      expect(result[:exam_boards]).to be_empty
    end
  end

  describe "false positives" do
    it "returns all-empty for a completely unrelated query" do
      result = extract("what time does the lesson start")
      EntityExtractor::DIMENSIONS.each do |dim|
        expect(result[dim]).to be_empty, "expected #{dim} to be empty"
      end
    end
  end
end
