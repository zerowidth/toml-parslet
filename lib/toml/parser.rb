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
      str("-").maybe >> match["1-9"] >> digit.repeat
    end

    rule(:float) do
      str("-").maybe >> digit.repeat(1) >> str(".") >> digit.repeat(1)
    end

    rule(:boolean) do
      str("true") | str("false")
    end

    rule(:datetime) do
      # 1979-05-27T07:32:00Z
      digit.repeat(4).as(:year)   >> str("-") >>
      digit.repeat(2).as(:month)  >> str("-") >>
      digit.repeat(2).as(:day)    >> str("T") >>
      digit.repeat(2).as(:hour)   >> str(":") >>
      digit.repeat(2).as(:minute) >> str(":") >>
      digit.repeat(2).as(:second) >> str("Z")
    end

    rule(:string_special)  { match['\0\t\n\r"\\\\'] }
    rule(:escaped_special) { str("\\") >> match['0tnr"\\\\'] }

    rule(:string) do
      str('"') >>
      (escaped_special | string_special.absent? >> any).repeat >>
      str('"')
    end

    def value_list(value_type)
      value_type >>
      (array_space >> str(",") >> array_space >> value_type).repeat
    end

    def array_contents
      # FIXME why does datetime need to be first?
      value_list(datetime) | value_list(integer) | value_list(float) |
        value_list(boolean) | value_list(string) | value_list(array)
    end

    rule :array do
      str("[") >> array_space >> array_contents >> array_space >> str("]")
    end

    rule :key do
      (match["\\[\\]="].absent? >> space.absent? >> any).repeat(1)
    end

    rule :key_group_name do
      whitespace >> str("[") >>
      (str("]").absent? >> any).repeat(1) >>
      str("]") >> whitespace >> comment.maybe
    end

    rule :value do
      datetime | float | integer | boolean | string | array
    end

    rule :assignment do
      whitespace >>
      key >> whitespace >> str("=") >> whitespace >> value >>
      whitespace >> comment.maybe
    end

    rule :assignments do
      assignment >>
      (newline >> (assignment | whitespace >> comment.maybe)).repeat
    end

    rule :key_group do
      key_group_name >>
      (newline >> (assignment | whitespace >> comment.maybe)).repeat
    end

    rule :document do
      empty_lines >>
      assignments >>
      empty_lines >>
      key_group.repeat >>
      newline.maybe
    end

    root :document
  end

end
