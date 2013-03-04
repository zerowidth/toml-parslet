#!/usr/bin/env bash
script_dir="$( dirname "${BASH_SOURCE[0]}" )"
BUNDLE_GEMFILE=$script_dir/../Gemfile bundle exec ruby $script_dir/../script/toml-test.rb
