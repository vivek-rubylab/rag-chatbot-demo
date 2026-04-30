require "rails_helper"

RSpec.describe QueryNormaliser do
  def normalise(query)
    described_class.new(query).call
  end

  describe "11+ shorthand" do
    it "normalises '11+' followed by text" do
      expect(normalise("11+ preparation")).to eq "eleven plus preparation"
    end

    it "normalises '11 +' with a space" do
      expect(normalise("11 +")).to eq "eleven plus"
    end

    it "normalises '11plus' (no space or symbol)" do
      expect(normalise("11plus")).to eq "eleven plus"
    end

    it "normalises 'eleven-plus'" do
      expect(normalise("eleven-plus")).to eq "eleven plus"
    end
  end

  describe "year group shorthand" do
    it "normalises 'Y5' to 'year 5'" do
      expect(normalise("Y5 maths")).to eq "year 5 maths"
    end

    it "normalises 'Y4' (uppercase)" do
      expect(normalise("Y4")).to eq "year 4"
    end

    it "normalises 'yr3'" do
      expect(normalise("yr3 english")).to eq "year 3 english"
    end

    it "normalises 'y6' (lowercase)" do
      expect(normalise("y6 courses")).to eq "year 6 courses"
    end

    it "is case-insensitive for shorthand" do
      expect(normalise("Y5")).to eq normalise("y5")
    end
  end

  describe "subject synonyms" do
    it "normalises 'nvr' to 'non-verbal reasoning'" do
      expect(normalise("nvr")).to eq "non-verbal reasoning"
    end

    it "normalises 'vr' to 'verbal reasoning'" do
      expect(normalise("vr")).to eq "verbal reasoning"
    end

    it "normalises 'mathematics' to 'maths'" do
      expect(normalise("mathematics")).to eq "maths"
    end

    it "normalises 'numeracy' to 'maths'" do
      expect(normalise("numeracy")).to eq "maths"
    end

    it "normalises 'literacy' to 'english'" do
      expect(normalise("literacy")).to eq "english"
    end

    it "leaves 'maths' unchanged" do
      expect(normalise("maths")).to eq "maths"
    end
  end

  describe "delivery format" do
    it "normalises 'remote' to 'online'" do
      expect(normalise("remote")).to eq "online"
    end

    it "normalises 'zoom tuition' to 'online tuition'" do
      expect(normalise("zoom tuition")).to eq "online tuition"
    end

    it "normalises 'face-to-face' to 'in-person'" do
      expect(normalise("face-to-face")).to eq "in-person"
    end
  end

  describe "exam boards" do
    it "normalises 'gl' to 'GL Assessment'" do
      expect(normalise("gl exam")).to eq "GL Assessment exam"
    end

    it "normalises 'durham' to 'CEM'" do
      expect(normalise("durham")).to eq "CEM"
    end
  end

  describe "unrelated text" do
    it "leaves unrelated text unchanged" do
      query = "what time does the class start"
      expect(normalise(query)).to eq query
    end
  end
end
