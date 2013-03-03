require "spec_helper"

describe TOML do
  describe ".load" do
    it "returns a hash representing the parsed document" do
      input = fixture "example.toml"
      expected = YAML.load(fixture "example.yaml")
      expect(TOML.load(input)).to eq(expected)
    end

    it "raises a ParseError with line and column when there is an error" do
      input = fixture "error.toml"
      expect { TOML.load(input) }.to raise_error(
        TOML::ParseError, /line 3 column 9/)
    end
  end
end
