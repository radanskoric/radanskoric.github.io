# frozen_string_literal: true

source "https://rubygems.org"
ruby RUBY_VERSION

gem "jekyll-theme-chirpy", "~> 6.2", ">= 6.2.3"

group :development, :test do
  gem "html-proofer", "~> 4.4"

  # This is needed because since Ruby 3.0 webrick is no longer a bundled gem.
  gem "webrick"

  gem "rspec"

  gem "pry", "~> 0.14.2"
  gem "pry-doc", require: false
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

