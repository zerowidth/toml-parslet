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

    rule(:array    => subtree(:a)) { a }

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
      {}.tap do |context|
        assignments.each do |assignment|
          key, value = assignment.first
          context[key.to_s] = value
        end
      end
    end

    def self.nested_hash_from_key(key, values)
      {}.tap do |outer|
        context = outer
        key.to_s.split(".").each do |key_part|
          # preserve position information for each part of the key
          sub_key = Parslet::Slice.new(key_part, key.offset, key.line_cache)
          context[sub_key] = {}
          context = context[sub_key]
        end
        context.merge! values
      end
    end

  end
end
