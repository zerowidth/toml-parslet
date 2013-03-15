module TOML
  class Transform < Parslet::Transform
    rule(:integer  => simple(:n))  { Integer(n) }
    rule(:float    => simple(:n))  { Float(n) }
    rule(:boolean  => simple(:b))  { b == "true" }
    rule(:datetime => simple(:dt)) { Time.parse dt }
    rule(:string   => simple(:s)) do
      s.to_s.gsub(
        /\\[0tnr"\\]/,
        "\\0" => "\0",
        "\\t" => "\t",
        "\\n" => "\n",
        "\\r" => "\r",
        "\\\\" => "\\",
        '\\"' => '"').gsub(/\\x([0-9a-fA-F]{2})/) { [$1].pack("H2") }
    end

    rule(:array => simple(:a)) { [] }
    rule(:array => subtree(:a)) { a }

    rule(:key => simple(:key), :value => subtree(:value)) do
      {key => value} # key is still a Parslet::Slice
    end

    rule(:assignments => simple(:values)) do
      {}
    end

    rule(:assignments => subtree(:values)) do |dict|
      if dict[:values].kind_of? Array
        combine_assignments dict[:values]
      else
        dict[:values]
      end
    end

    rule(:group_name => simple(:key)) do |dict|
      nested_hash_from_key dict[:key], {}
    end

    rule(:group_name => simple(:key),
         :assignments => simple(:values)) do |dict|
      nested_hash_from_key dict[:key], {}
    end

    rule(:group_name => simple(:key),
         :assignments => subtree(:values)) do |dict|

      values = if dict[:values].kind_of? Array
                 combine_assignments dict[:values]
               else
                 dict[:values]
               end
      nested_hash_from_key dict[:key], values
    end

    rule(:key_group => subtree(:values)) { values }

    rule(:document => subtree(:assignment_groups)) do |dict|
      groups = dict[:assignment_groups]
      groups = [groups] if groups.kind_of?(Hash)
      groups.inject({}, &method(:merge_nested))
    end

    def self.merge_nested(existing, updates)
      updates.each do |key, value|
        key_s = key.to_s

        if existing.has_key? key_s
          if existing[key_s].kind_of?(Hash) && value.kind_of?(Hash)
            existing[key_s] = merge_nested(existing[key_s], value)
          else
            line, column = key.line_and_column
            raise TransformError,
              "Cannot reassign existing key #{key_s} at line #{line} column #{column}"
          end
        else
          if value.kind_of? Hash
            existing[key_s] = merge_nested({}, value)
          else
            existing[key_s] = value
          end
        end
      end

      existing
    end

    def self.combine_assignments(assignments)
      {}.tap do |combined|
        assignments.each do |assignment|
          key, value = assignment.first
          combined[key.to_s] = value
        end
      end
    end

    # Internal: create a nested hash from a key name and values
    #
    # key    - a dotted key such as "foo.bar"
    # values - the values to assign at the innermost level
    #
    # Example:
    #
    #   nested_hash_from_key("foo.bar", "a" => 1)
    #   # => {"foo" => {"bar" => {"a" => 1}}}
    #
    def self.nested_hash_from_key(key, values)
      key_part, remainder = key.to_s.split(".", 2)

      # preserve position information for each part of the key for error
      # reporting later on during the transform:
      sub_key = Parslet::Slice.new(key_part, key.offset, key.line_cache)

      if remainder
        rest = Parslet::Slice.new(remainder, key.offset, key.line_cache)
        {sub_key => nested_hash_from_key(rest, values)}
      else
        {sub_key => values}
      end
    end

  end
end
