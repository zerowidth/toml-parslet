module TOML

  class Parser < Parslet::Parser
    rule(:digit)      { match["0-9"] }
    rule(:space)      { match["\t "] }
    rule(:whitespace) { space.repeat }
    rule(:newline)    { str("\n") }

    rule(:array_space) do
      (space | (comment.maybe >> newline)).repeat
    end

    rule(:comment) do
      str("#") >> (newline.absent? >> any).repeat
    end

    rule(:empty_lines) do
      (whitespace >> comment.maybe >> newline).repeat
    end

    rule(:integer) do
      (str("-").maybe >> match["1-9"] >> digit.repeat).as(:integer)
    end

    rule(:float) do
      (str("-").maybe >> digit.repeat(1) >>
       str(".") >> digit.repeat(1)).as(:float)
    end

    rule(:boolean) do
      (str("true") | str("false")).as(:boolean)
    end

    rule(:datetime) do
      (digit.repeat(4) >> str("-") >>
       digit.repeat(2) >> str("-") >>
       digit.repeat(2) >> str("T") >>
       digit.repeat(2) >> str(":") >>
       digit.repeat(2) >> str(":") >>
       digit.repeat(2) >> str("Z")).as(:datetime)
    end

    rule(:string_special)  { match['\0\t\n\r"\\\\'] }
    rule(:escaped_special) { str("\\") >> match['0tnr"\\\\'] }

    rule(:string) do
      str('"') >>
      ((escaped_special | string_special.absent? >> any).repeat).as(:string) >>
      str('"')
    end

    def value_list(value_type)
      value_type >>
      (array_space >> str(",") >> array_space >> value_type).repeat
    end

    def array_contents
      value_list(datetime) | value_list(float) | value_list(integer) |
        value_list(boolean) | value_list(string) | value_list(array)
    end

    rule :array do
      (str("[") >> array_space >>
      array_contents.repeat(1) >>
      array_space >> str("]")).as(:array)
    end

    rule :key do
      (match["\\[\\]="].absent? >> space.absent? >> any).repeat(1)
    end

    rule :key_group_name do
      whitespace >> str("[") >>
      (str("]").absent? >> any).repeat(1).as(:group_name) >>
      str("]") >> whitespace >> comment.maybe
    end

    rule :value do
      datetime | float | integer | boolean | string | array
    end

    rule :assignment do
      whitespace >>
      key.as(:key) >>
      whitespace >> str("=") >> whitespace >>
      value.as(:value) >>
      whitespace >> comment.maybe
    end

    rule :assignments do
      assignment >>
      (newline >> (assignment | whitespace >> comment.maybe)).repeat
    end

    rule :key_group do
      (key_group_name >>
       (newline >>
        (assignment | whitespace >> comment.maybe)).repeat.as(:assignments)
      ).as(:key_group)
    end

    rule :document do
      (empty_lines >>
       assignments.repeat.as(:globals) >>
       empty_lines >>
       key_group.repeat >>
       newline.maybe).as(:document)
    end

    root :document
  end

end
