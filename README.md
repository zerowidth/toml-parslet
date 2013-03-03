# toml-parslet

This is a [TOML](https://github.com/mojombo/toml) parser for loading a hash from
a TOML document.

It supports revision [b098bd2](https://github.com/mojombo/toml/commit/b098bd2)
of the TOML spec.

## Is it awesome?

Yes.

## Right on.

While this is indeed a fully functioning TOML parser, I wrote this as a personal
exercise and for a series of blog posts describing how to use
[Parslet](http://kschiess.github.com/parslet/) for parsing a simple text file
format.

* Part 1 - [Parsing TOML in Ruby with Parslet](http://zerowidth.com/2013/02/24/parsing-toml-in-ruby-with-parslet.html)
* Part 2 - [Annotating a TOML Parse Tree](http://zerowidth.com/2013/02/28/annotating-a-toml-parse-tree.html)
* Part 3 - [Transforming a TOML Parse Tree](http://zerowidth.com/2013/03/02/transforming-a-toml-parse-tree.html)

It's set up as a ruby gem, but I'll only release it officially upon request.

## Usage

```ruby
require "toml-parslet"
TOML.load File.read("example.toml")
```

## Contributing

Pull requests with tests, plz.

