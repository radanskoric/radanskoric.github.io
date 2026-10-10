# Project guide

Personal website and technical blog at https://radan.dev. Built with Jekyll and the `jekyll-theme-chirpy` gem; GitHub Actions builds and deploys to GitHub Pages.

## Where to edit

- `_posts/YYYY-MM-DD-slug.markdown`: blog posts with YAML front matter (`title`, `date`, `categories`, `tags`; optional `image`). Do not ever draft a post from scratch. The first version is always human written.
- `_posts/_includes/`: snippets embedded with `include_relative`; keep displayed code and runnable demos in sync.
- `_tabs/`: navigation pages; `_layouts/` and `_includes/`: local overrides of the gem theme. When updating gems, first inspect and detect significant local changes so that you can recreate them on top of new templates from the new version of the theme.
- `assets/css/jekyll-theme-chirpy.scss`: custom styles after `@import 'main'`; `assets/js/`: interactive examples; `assets/img/posts/`: post images.
- `_config.yml`: site settings. Preserve existing post URLs (`/:categories/:slug`) when editing categories or filenames.
- `_plugins/`: Jekyll hooks; `gems/commands/`: local gem providing `bundle exec jekyll promote` for promotion links.
- `spec/posts/`: tests for blog code examples; `spec/rails_app/`: supporting Rails app, not the website. `talks/`: standalone slide decks.

## Development and checks

Use Ruby defined in `.tool-versions`; 

```sh
bundle install
bundle exec jekyll serve
JEKYLL_ENV=production bundle exec jekyll build
bundle exec htmlproofer _site --disable-external --ignore-urls '/^http:\/\/127.0.0.1/,/^http:\/\/0.0.0.0/,/^http:\/\/localhost/'
```

For changes to Ruby examples, run the relevant `bundle exec rspec spec/posts/<file>_spec.rb`. CI runs the site build and HTML checks, not RSpec. For UI changes, also inspect the rendered page and its interactive examples.

Edit source files, not generated `_site/` or `.jekyll-cache/`. `assets/lib` is a Chirpy assets submodule; initialize it with `git submodule update --init --recursive` if needed. The last-modified hook reads Git history, so shallow checkouts can produce incomplete dates.
