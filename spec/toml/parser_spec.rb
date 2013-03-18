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
    end

    it "parses escaped sequences in strings" do
      expect(value_parser).to     parse('"\\b\\t\\n\\f\\r\\"\\/\\\\"')
      expect(value_parser).to     parse('"no way, jos\\u00E9"')
      expect(value_parser).to_not parse("\"hello\nworld\"")
      expect(value_parser).to_not parse("\"hello/world\"")
      expect(value_parser).to_not parse(%Q("\u001F"))
      expect(value_parser).to     parse('"\\u001F"')
    end

    it "parses integers into {:integer => 'digits'}" do
      expect(value_parser.parse("1234")).to eq :integer => "1234"
    end

    it "parses floats into {:float => 'digits'}" do
      expect(value_parser.parse("-0.123")).to eq :float => "-0.123"
    end

    it "parses booleans into {:boolean => 'value'}" do
      expect(value_parser.parse("true")).to eq :boolean => "true"
    end

    it "parses datetimes into hashes of date/time data" do
      expect(value_parser.parse("1979-05-27T07:32:00Z")).to eq(
        :datetime => "1979-05-27T07:32:00Z"
      )
    end

    it "parses strings into {:string => 'string contents'}" do
      expect(value_parser.parse('"hello world"')).to eq(
        :string => "hello world")
    end

    it "captures escaped special characters in captured strings" do
      expect(value_parser.parse('"hello\\nworld"')).to eq(
        :string => "hello\\nworld")
    end
  end

  context "array parsing" do
    let(:array_parser) { parser.array }

    it "parses empty arrays" do
      expect(array_parser).to parse("[]")
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
      expect(array_parser).to parse("[\n1\n,\n2\n]")
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

    it "parses arrays with arbitrary comments and lines within" do
      expect(array_parser).to parse(%Q([1,#c\n2]))
      expect(array_parser).to parse(
        %Q([ 1, 2,#comment\n \n\t# a comment, , ,\n3#xx\n\t,\t\n\n\n4]))
    end

    it "parses arrays with trailing commas" do
      expect(array_parser).to parse("[1,2,]")
      expect(array_parser).to parse("[1,2\n,\t]")
    end

    it "captures arrays as :array => [ value, value, ... ]" do
      expect(array_parser.parse("[1,2]")).to eq(
        :array => [ {:integer => "1"}, {:integer => "2"}])
    end

    it "captures an empty array" do
      expect(array_parser.parse("[]")).to eq(:array => "[]")
    end

    it "captures nested arrays" do
      expect(array_parser.parse("[ [1,2] ]")).to eq(
        :array => [
          {:array => [ {:integer => "1"}, {:integer => "2"}]}
        ])
    end
  end

  context "assignment" do
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

    it "does not parse a comment" do
      expect(ap).to_not parse("#comment=1")
    end

    it "captures the key and the value" do
      expect(ap.parse("thing = 1")).to eq(
        :key => "thing", :value => {:integer => "1"})
    end
  end

  context "key group names" do
    let(:gn) { parser.group_name }

    it "parses key group names" do
      expect(gn).to     parse("[key.group.name]")
      expect(gn).to     parse("    [key.group.name]")
      expect(gn).to     parse("[key group]")
      expect(gn).to     parse("[key group]    ")
      expect(gn).to_not parse("[key]]")
    end

    it "does not parse an empty .. dotted name" do
      expect(gn).to_not parse("[key..group]")
    end

    it "allows a comment after a group name" do
      expect(gn).to parse("[key.group.name] # comment")
      expect(gn).to parse("[key.group.name]#comment")
    end

    it "captures as :group_name" do
      expect(gn.parse("[key.group.name]")).to eq(
        :group_name => "key.group.name"
      )
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

    it "parses an assignment with whitespace" do
      expect(ap).to parse("    key =    12345")
    end

    it "parses an assignment with a comment" do
      expect(ap).to parse("key = 1234 # comment")
      expect(ap).to parse("key = 1234#comment can contain almost anything")
    end

    it "captures a list of assignments" do
      expect(ap.parse("a=1\nb=2")).to eq(
        :assignments => [
          {:key => "a", :value => {:integer => "1"}},
          {:key => "b", :value => {:integer => "2"}},
        ]
      )
    end

    it "captures an empty string" do
      expect(ap.parse("")).to eq(:assignments => "")
    end

    it "captures an assignment after a comment and newlines" do
      expect(ap.parse("#comment\na=1")).to eq(
        :assignments => [{:key => "a", :value => {:integer => "1"}}]
      )

      expect(ap.parse("#comment\n\t\n\na=1")).to eq(
        :assignments => [{:key => "a", :value => {:integer => "1"}}]
      )
    end

    it "captures just comments as a string" do
      expect(ap.parse("#comment\n")).to eq(
        :assignments => "#comment\n"
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

    it "captures the group name and assignments" do
      expect(kgp.parse("[kg]\na=1\nb=2")).to eq(
        :key_group =>
          {:group_name => "kg",
          :assignments => [
            {:key => "a", :value => {:integer => "1"}},
            {:key => "b", :value => {:integer => "2"}}]}
      )
    end

    it "captures empty assignments as a string" do
      expect(kgp.parse("[kg]\n#comment\n\t\n")).to eq(
        :key_group =>
          {:group_name => "kg",
           :assignments => "#comment\n\t\n"}
      )
    end

    it "captures a single assignment in a key group" do
      expect(kgp.parse("[kg]\na=1")).to eq(
        :key_group => {
          :group_name => "kg",
          :assignments => {:key => "a", :value => {:integer => "1"}}}
      )
    end

  end

  it "can parse a valid TOML document" do
    expect(parser).to parse(fixture("example.toml"))
  end

  it "can parse a hard TOML document" do
    expect(parser).to parse(fixture("hard_example.toml"))
  end

  it "captures an simple document as a parse tree" do
    expect(parser.parse(fixture("simple.toml"))).to eq(
      :document =>
      [{:assignments =>
        {:key => "title", :value => {:string => "global title"}}},
       {:key_group =>
        {:group_name => "group1",
         :assignments => [
           {:key => "a", :value => {:integer => "1"}},
           {:key => "b", :value => {:integer => "2"}}]}},
       {:key_group =>
        {:group_name => "group2",
         :assignments =>
          {:key => "c", :value => {:array => [
             {:integer => "3"},
             {:integer => "4"}
        ]}}}}]
    )
  end

  it "captures a valid document as a parse tree" do
    expect(parser.parse(fixture("example.toml"))).to eq(
      :document => [
        {:assignments =>
         [{:key => "title", :value => {:string => "TOML Example"}}]},
        {:key_group =>
         {:group_name => "owner",
          :assignments => [
            {:key => "name", :value => {:string => "Tom Preston-Werner"}},
            {:key => "organization", :value => {:string => "GitHub"}},
            {:key => "bio", :value => {:string => "GitHub Cofounder & CEO\\nLikes tater tots and beer."}},
            {:key => "dob", :value => {:datetime => "1979-05-27T07:32:00Z"}}]}
         },
        {:key_group =>
          {:group_name => "database",
           :assignments => [
            {:key => "server", :value => {:string => "192.168.1.1"}},
            {:key => "ports", :value => {:array => [
              {:integer => "8001"},
              {:integer => "8001"},
              {:integer => "8002"} ]}},
            {:key => "connection_max", :value => {:integer => "5000"}},
            {:key => "enabled", :value => {:boolean => "true"}}]}
         },
        {:key_group =>
         {:group_name => "servers",
          :assignments=>"\n  # You can indent as you please. Tabs or spaces. TOML don't care.\n  "}
         },
        {:key_group =>
          {:group_name => "servers.alpha",
           :assignments => [
             {:key => "ip", :value => {:string => "10.0.0.1"}},
             {:key => "dc", :value => {:string => "eqdc10"}}]}
         },
        {:key_group =>
          {:group_name => "servers.beta",
           :assignments => [
             {:key => "ip", :value => {:string => "10.0.0.2"}},
             {:key => "dc", :value => {:string => "eqdc10"}}]}
         },
        {:key_group =>
          {:group_name => "clients",
           :assignments => [
             {:key => "data", :value => {:array => [
               {:array => [
                 {:string => "gamma"},
                 {:string => "delta"}]},
               {:array => [
                 {:integer => "1"},
                 {:integer => "2"}]}]}},
             {:key => "hosts", :value => {:array => [
               {:string => "alpha"},
               {:string => "omega"}]}}]}
          }]
    )
  end

  it "captures an empty document as a string match" do
    expect(parser.parse("\n\n#comment\n\n")).to eq(
      :document => {:assignments => "\n\n#comment\n\n"}
    )
  end

end
