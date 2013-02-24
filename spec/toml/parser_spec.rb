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

    it "does not parse mixed arrays" do
      expect(array_parser).to_not parse(
        %q([1, 2, "three"])
      )
    end

  end

  context "assignments" do
    let(:ap) { parser.assignment }

    it "parses keys" do
      expect(parser.key).to     parse("foobar")
      expect(parser.key).to     parse("lolwhat.noWAY")
      expect(parser.key).to_not parse("no white\tspace")
      expect(parser.key).to_not parse("noequal=thing")
    end

    it "parses an assignment to a simple value" do
      expect(ap).to parse('key=3.14')
      expect(ap).to parse('key = 10')
      expect(ap).to parse('key = 10.10')
      expect(ap).to parse('key = true')
      expect(ap).to parse('key = "value"')
      expect(ap).to parse('foobar.baz="value"')
    end

    it "parses an assignment to an array" do
      expect(ap).to parse(
        "array = [ 1,
                   2,
                   3 ]")
    end

    it "parses an assignment with whitespace" do
      expect(ap).to parse("    key =    12345")
    end
  end

  context "key group names" do
    let(:kgp) { parser.key_group_name }

    it "parses key group names" do
      expect(kgp).to     parse("[key.group.name]")
      expect(kgp).to     parse("    [key.group.name]")
      expect(kgp).to     parse("[key group]")
      expect(kgp).to     parse("[key group]    ")
      expect(kgp).to_not parse("[key]]")
    end
  end

  context "assignments" do
    let(:ap) { parser.assignments }

    it "parses a single assignment" do
      expect(ap).to parse(
        %q(key1 = "some string"))
    end

    it "parses a series of assignments" do
      expect(ap).to parse(
        %q(key1 = "some string"
           key2 = 3.14159
           birthday = 1979-05-27T07:32:00Z)
      )
    end

    it "ignores empty lines" do
      expect(ap).to parse(
        %Q(key1 = "some string"\n\t\t
           key2 = 3.14159
           birthday = 1979-05-27T07:32:00Z)
      )
    end
  end

  context "key groups" do
    let(:kgp) { parser.key_group }

    it "parses an empty key group" do
      expect(kgp).to parse("[empty group]")
      expect(kgp).to parse("[empty group]\n\n\n")
    end

    it "parses a key group with assignments" do
      expect(kgp).to parse(
        %Q([key group]
        key = "value"
        pi = 3.14159)
      )
    end

  end
end
