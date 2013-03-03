require "parslet"
require "toml/version"
require "toml/parser"
require "toml/transform"

module TOML

  Error          = Class.new StandardError
  ParseError     = Class.new Error
  TransformError = Class.new Error

  def self.load(str)
    Transform.new.apply(Parser.new.parse(str))
  rescue Parslet::ParseFailed => e
    deepest = deepest_cause e.cause
    line, column = deepest.source.line_and_column(deepest.pos)
    raise ParseError, "unexpected input at line #{line} column #{column}"
  end

  # Internal: helper for finding the deepest cause for a parse error
  def self.deepest_cause(cause)
    if cause.children.any?
      deepest_cause(cause.children.first)
    else
      cause
    end
  end
end
