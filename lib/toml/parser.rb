module TOML

  class Parser < Parslet::Parser
    rule(:digit)      { match["0-9"] }
    rule(:space)      { match["\t "] }
    rule(:space?)     { space.repeat }
    rule(:newline)    { str("\n") }

    rule(:array_space) do
      (space | (comment? >> newline)).repeat
    end

    rule(:comment?) do
      (str("#") >> (newline.absent? >> any).repeat).maybe
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
    rule(:escaped_special) do
      str("\\") >>
      (match['0tnr"\\\\'] |
       str('x') >> match['a-fA-F0-9'].repeat(2) )
    end

    rule(:string) do
      str('"') >>
      ((escaped_special | string_special.absent? >> any).repeat).as(:string) >>
      str('"')
    end

    def value_list(value_type)
      value_type >>
      (array_space >> str(",") >> array_space >> value_type).repeat >>
      array_space.maybe >> str(",").maybe
    end

    def array_contents
      value_list(datetime) | value_list(float) | value_list(integer) |
        value_list(boolean) | value_list(string) | value_list(array)
    end

    rule :array do
      (str("[") >> array_space >>
      array_contents.repeat >>
      array_space >> str("]")).as(:array)
    end

    rule :key do
      str("#").absent? >> newline.absent? >>
      (match["\\[\\]="].absent? >> space.absent? >> any).repeat(1)
    end

    rule :value do
      datetime | float | integer | boolean | string | array
    end

    rule :assignment do
      key.as(:key) >>
      space? >> str("=") >> space? >>
      value.as(:value)
    end

    rule :group_name_part do
      (str("]").absent? >> str(".").absent? >> any).repeat(1)
    end

    rule :dotted_name do
      group_name_part >> (str(".") >> group_name_part).repeat
    end

    rule :group_name do
      space? >> str("[") >>
      dotted_name.as(:group_name) >>
      str("]") >> space? >> comment?
    end

    rule :assignment_line do
      space? >> assignment.maybe >> space? >> comment?
    end

    rule :assignments do
      (assignment_line >> (newline >> assignment_line).repeat).as(:assignments)
    end

    rule :key_group do
      (group_name >>
       (newline >> assignments).maybe).as(:key_group)
    end

    rule :document do
      ((key_group | assignments) >>
       key_group.repeat >>
       newline.maybe).as(:document)
    end

    root :document
  end

end
