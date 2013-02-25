module TOML
  class Transform < Parslet::Transform
    rule(:integer  => simple(:n))  { Integer(n) }
    rule(:float    => simple(:n))  { Float(n) }
    rule(:boolean  => simple(:b))  { b == "true" }
    rule(:datetime => simple(:dt)) { Time.parse dt }
    rule(:string   => simple(:s))  { s.to_s }
    rule(:array    => subtree(:a)) { a }

    rule(:key => simple(:key), :value => subtree(:value)) do
      [key, value]
    end

    rule(:globals => subtree(:values)) do |dict|
      combine_assignments(dict[:values])
    end

    def self.combine_assignments(assignments)
      {}.tap do |context|
        assignments.each do |key, value|
          context[key.to_s] = value
        end
      end
    end

    rule(:group_name => simple(:key), :assignments => subtree(:assignments)) do |dict|
      outer = {}
      current = outer
      dict[:key].to_s.split(".").each do |key|
        current[key] = {}
        current = current[key]
      end
      current.merge! combine_assignments(dict[:assignments])
      outer
    end

    rule(:key_group => subtree(:values)) { values }

    rule(:document => subtree(:values)) do
      {}.tap do |data|
        values.each do |sub_hash|
          data.merge! sub_hash
        end
      end
    end

  end
end
