require "spec_helper"

describe TOML::Parser do
  let(:parser) { TOML::Parser.new }

  context "value parsing" do
    let(:value_parser) { parser.value }

    it "parses integers" do
      expect(value_parser).to     parse("1")
      expect(value_parser).to     parse("-123")
      expect(value_parser).to     parse("120381")
      expect(value_parser).to     parse("181")
      expect(value_parser).to_not parse("0181")
    end

    it "parses floats" do
      expect(value_parser).to     parse("0.1")
      expect(value_parser).to     parse("3.14159")
      expect(value_parser).to     parse("-0.00001")
      expect(value_parser).to_not parse(".1")
    end

    it "parses booleans" do
      expect(value_parser).to     parse("true")
      expect(value_parser).to     parse("false")
      expect(value_parser).to_not parse("truefalse")
    end

    it "parses datetimes" do
      expect(value_parser).to     parse("1979-05-27T07:32:00Z")
      expect(value_parser).to     parse("2013-02-24T17:26:21Z")
      expect(value_parser).to_not parse("1979l05-27 07:32:00")
    end

    it "parses strings" do
      expect(value_parser).to     parse('""')
      expect(value_parser).to     parse('"hello world"')
      expect(value_parser).to     parse('"hello\\nworld"')
      expect(value_parser).to     parse('"hello\\t\\n\\\\\\0world\\n"')
      expect(value_parser).to_not parse("\"hello\nworld\"")
    end
  end
end
