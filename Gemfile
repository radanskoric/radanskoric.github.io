# frozen_string_literal: true

source "https://rubygems.org"
ruby RUBY_VERSION

gem "jekyll-theme-chirpy", "~> 6.3"

group :development, :test do
  gem "html-proofer", "~> 5.0"

  gem "pry", "~> 0.15.2"
  gem "pry-doc", require: false

  # The whole section below is gems for tests accompanying blog posts.
  # The idea is to test the code that appears in the posts so I know
  # if it broke with new versions of ruby or gems.
  gem "rspec"

  # For AR related blog posts.
  gem "activerecord", "~> 8.0"
  gem "sqlite3", "~> 2.7"
  gem 'concurrent-ruby', '~> 1.3'
end

group :jekyll_plugins do
  gem "commands", "0.1.0", path: "gems/commands"
end

# === Various platform normalizations ===

# Windows and JRuby does not include zoneinfo files, so bundle the tzinfo-data gem
# and associated library.
platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end

# Performance-booster for watching directories on Windows
gem "wdm", "~> 0.1.1", :platforms => [:mingw, :x64_mingw, :mswin]

# Lock `http_parser.rb` gem to `v0.6.x` on JRuby builds since newer versions of the gem
# do not have a Java counterpart.
gem "http_parser.rb", "~> 0.6.0", :platforms => [:jruby]

