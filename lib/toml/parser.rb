module TOML

  class Parser < Parslet::Parser
    rule(:digit)       { match["0-9"] }

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

    rule :value do
      integer | float | boolean | datetime | string
    end

    # root :document
  end

end
