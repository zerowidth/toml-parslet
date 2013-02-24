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

  context "array parsing" do
    let(:array_parser) { parser.array }

    it "does not parse empty arrays" do
      expect(array_parser).to_not parse("[]")
    end

    it "parses arrays of integers" do
      expect(array_parser).to parse("[1]")
      expect(array_parser).to parse("[1, 2, 3, 4, 5]")
    end

    it "parses arrays of floats" do
      expect(array_parser).to parse("[0.1, -0.1, 3.14159]")
    end

    it "parses arrays of booleans" do
      expect(array_parser).to parse("[ true, false, true, true ]")
    end

    it "parses arrays of datetimes" do
      expect(array_parser).to parse("[1979-05-27T07:32:00Z]")#, 2013-02-24T17:26:21Z]")
    end

    it "parses arrays of strings" do
      expect(array_parser).to parse(
        %q([
          "hello, world",
          "goodbye!"
        ]))
    end

    it "ignores whitespace in arrays" do
      expect(array_parser).to parse("[\n\n\t1  , 2,     3\t,4\n]")
    end

    it "parses arrays of arrays" do
      expect(array_parser).to parse(
        %q([ [1, 2, 3], ["foo", "bar"] ]))
    end

  end
end
