require "spec_helper"

describe TOML::Transform do
  let(:xform) { TOML::Transform.new }

  context "values" do
    it "transforms an integer value" do
      expect(xform.apply(:integer => "1")).to eq(1)
    end

    it "transforms a float" do
      expect(xform.apply(:float => "0.123")).to eq(0.123)
    end

    it "transforms a boolean" do
      expect(xform.apply(:boolean => "true")).to eq(true)
      expect(xform.apply(:boolean => "false")).to eq(false)
    end

    it "transforms a datetime" do
      expect(xform.apply(:datetime => "1979-05-27T07:32:00Z")).to eq(
        Time.parse("1979-05-27T07:32:00Z"))
    end

    it "transforms a string" do
      expect(xform.apply(:string => "a string")).to eq("a string")
    end

    it "unescapes special characters in captured strings" do
      expect(xform.apply(:string => "a\\nb")).to eq("a\nb")
    end
  end

  context "arrays" do
    it "transforms an array of integers" do
      input = { :array => [ {:integer => "1"}, {:integer => "2"} ] }
      expect( xform.apply(input) ).to eq([1,2])
    end

    it "transforms nested arrays" do
      input = {
        :array => [
          { :array => [ {:integer => "1"}, {:integer => "2"} ] },
          { :array => [ {:float => "0.1"}, {:float => "0.2"} ] }
        ]
      }
      expect( xform.apply(input) ).to eq([[1,2], [0.1,0.2]])
    end
  end

  context "key/value assignment" do
    it "converts a key/value pair into a pairs" do
      input = {:key => "a key", :value => "a value"}
      expect( xform.apply(input) ).to eq("a key" => "a value")
    end

    it "converts a key/value pair with an array value" do
      input = {:key => "a key", :value => [[1,2],[3,4]]}
      expect( xform.apply(input) ).to eq("a key" => [[1,2],[3,4]])
    end

  end

  context "a list of global assignments" do
    it "converts a list of global assignments into a hash" do
      input = {:assignments =>
               [{:key => "c", :value => {:integer => "3"}},
                {:key => "d", :value => {:integer => "4"}}]}
      expect(xform.apply(input)).to eq("c" => 3, "d" => 4)
    end

    it "converts an empty (comments-only) assignments list" do
      input = {:assignments => "\n#comment"}
      expect(xform.apply(input)).to eq({})
    end

    it "converts an array assignment" do
      input = {:assignments => {:key => "a", :value => [1, 2]}}
      expect( xform.apply(input) ).to eq( "a" => [1,2] )
    end
  end

  context "a key group" do
    it "converts a group name and assignments into a hash" do
      input = {:group_name => "group",
               :assignments => [{"c" => 1}, {"d" => 2}]}
      expect(xform.apply(input)).to eq(
        "group" => {"c" => 1, "d" => 2}
      )
    end

    it "converts a complex group name and values into a nested hash" do
      input = {:group_name => "foo.bar",
               :assignments => [{"c" => 1}, {"d" => 2}]}
      expect(xform.apply(input)).to eq(
        "foo" => {"bar" => {"c" => 1, "d" => 2}}
      )
    end

    it "converts an empty key group (comments-only) into a hash" do
      input = {:group_name => "foo.bar",
               :assignments => "\n#comment"}
      expect(xform.apply(input)).to eq(
        "foo" => {"bar" => {}}
      )
    end
  end

  it "converts a simple TOML doc into a hash" do
    input = TOML::Parser.new.parse(fixture("simple.toml"))
    expect(xform.apply(input)).to eq(
      "title" => "global title",
      "group1" => {"a" => 1, "b" => 2},
      "group2" => {"c" => [3, 4]}
    )
  end

  it "converts a full TOML doc into a hash" do
    input = TOML::Parser.new.parse(fixture("example.toml"))
    expect(xform.apply(input)).to eq(
      "title" => "TOML Example",
      "owner" => {
        "name" => "Tom Preston-Werner",
        "organization" => "GitHub",
        "bio" => "GitHub Cofounder & CEO\nLikes tater tots and beer.",
        "dob" => Time.parse("1979-05-27 07:32:00 UTC")
      },
      "database" => {
        "server" => "192.168.1.1",
        "ports" => [8001, 8001, 8002],
        "connection_max" => 5000,
        "enabled" => true},
        "servers" => {
          "beta" => {
            "ip" => "10.0.0.2",
            "dc" => "eqdc10"
          }
        },
        "clients" => {
          "data" => [ ["gamma", "delta"], [1, 2] ],
          "hosts" => ["alpha", "omega"]
        }
    )
  end

  it "raises an error when attempting to reassign a key" do
    input = TOML::Parser.new.parse(fixture("reassign_key.toml"))
    expect { xform.apply(input) }.to raise_error(/reassign/)
  end

  it "raises an error when attempting to reassign a value" do
    input = TOML::Parser.new.parse(fixture("reassign_value.toml"))
    expect { xform.apply(input) }.to raise_error(/reassign/)
  end

end

