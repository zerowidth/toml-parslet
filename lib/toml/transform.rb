module TOML
  class Transform < Parslet::Transform
    rule(:integer  => simple(:n))  { Integer(n) }
    rule(:float    => simple(:n))  { Float(n) }
    rule(:boolean  => simple(:b))  { b == "true" }
    rule(:datetime => simple(:dt)) { Time.parse dt }
    rule(:string   => simple(:s))  { s.to_s }
    rule(:array    => subtree(:a)) { a }

    rule(:key => simple(:key), :value => subtree(:value)) do
      {key.to_s => value}
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

    rule(:document => subtree(:values)) do
      {}.tap do |data|
        values.each do |sub_hash|
          data.merge! sub_hash
        end
      end
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
        current = outer
        key.to_s.split(".").each do |key_part|
          current[key_part] = {}
          current = current[key_part]
        end
        current.merge! values
      end
    end


  end
end
